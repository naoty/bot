require "okura/serializer"
require "redis"

module Bot
  module Brain
    class Classifier
      CATEGORIES = %i(normal favorite).freeze
      CATEGORY_THRESHOLD = 3

      def initialize
        dictionary_path = Bot.root_path.join("assets/okura-dic").to_s
        @tagger = Okura::Serializer::FormatInfo.create_tagger(dictionary_path)
        @redis = Redis.new
      end

      def train(screen_name, text, category)
        features = parse(text)
        features.each do |feature|
          train_by_feature_and_category(feature, category)
        end
        train_by_feature_and_category(screen_name, category)
      end

      def classify(screen_name, text)
        favorite_probability = calculate_probability(screen_name, text, :favorite)
        normal_probability = calculate_probability(screen_name, text, :normal)
        (favorite_probability > normal_probability * CATEGORY_THRESHOLD) ? :favorite : :normal
      end

      private

      def parse(text)
        nodes = @tagger.parse(text)
        words = nodes.mincost_path.map(&:word).uniq
        words.select { |word| word.left.text =~ /名詞/ }.map(&:surface)
      end

      def train_by_feature_and_category(feature, category)
        increment_item_count_in_feature_and_category(feature, category)
        increment_item_count_in_category(category)
        if category == :favorite
          decrement_item_count_in_feature_and_category(feature, :normal)
          decrement_item_count_in_category(:normal)
        end
      end

      def increment_item_count_in_feature_and_category(feature, category)
        key = "bot:features:#{feature}"
        field = "bot:categories:#{category}"

        if !@redis.exists(key) || !@redis.hexists(key, field)
          @redis.hset(key, field, 0)
        end
        @redis.hincrby(key, field, 1)
      end

      def increment_item_count_in_category(category)
        key = "bot:categories:#{category}"
        @redis.set(key, 0) unless @redis.exists(key)
        @redis.incr(key)
      end

      def decrement_item_count_in_feature_and_category(feature, category)
        key = "bot:features:#{feature}"
        field = "bot:categories:#{category}"

        return unless @redis.exists(key)
        return unless @redis.hexists(key, field)
        return if @redis.hget(key, field).to_i < 1
        @redis.hdecrby(key, field, 1)
      end

      def decrement_item_count_in_category(category)
        key = "bot:categories:#{category}"
        return unless @redis.exists(key)
        return if @redis.get(key).to_i < 1
        @redis.decr(key)
      end

      def calculate_probability(screen_name, text, category)
        features = parse(text) + [screen_name]
        cumulated_probability = features.reduce(1) do |probability, feature|
          probability *= calculate_feature_probability(feature, category)
        end
        category_probability = calculate_category_probability(category)
        cumulated_probability * category_probability
      end

      def calculate_feature_probability(feature, category)
        features_key = "bot:features:#{feature}"
        categories_key = "bot:categories:#{category}"

        return 0 unless @redis.exists(features_key)
        return 0 unless @redis.hexists(features_key, categories_key)
        return 0 if @redis.get(categories_key).to_i == 0
        @redis.hget(features_key, categories_key).to_f / @redis.get(categories_key).to_i
      end

      def calculate_category_probability(category)
        key = "bot:categories:#{category}"
        @redis.get(key).to_f / total_feature_count
      end

      def total_feature_count
        CATEGORIES.inject(0) do |count, category|
          key = "bot:categories:#{category}"
          count += @redis.get(key).to_i
        end
      end
    end
  end
end
