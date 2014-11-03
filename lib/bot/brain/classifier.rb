require "okura/serializer"
require "redis"

module Bot
  module Brain
    class Classifier
      CATEGORIES = %i(normal favorite).freeze
      CATEGORY_THRESHOLD = 3

      def initialize
        dictionary_path = File.expand_path("../../../assets/okura-dic", __dir__)
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
        if !@redis.exists(feature) || !@redis.hexists(feature, category)
          @redis.hset(feature, category, 0)
        end
        @redis.hincrby(feature, category, 1)
      end

      def increment_item_count_in_category(category)
        @redis.set(category, 0) unless @redis.exists(category)
        @redis.incr(category)
      end

      def decrement_item_count_in_feature_and_category(feature, category)
        return unless @redis.exists(feature)
        return unless @redis.hexists(feature, category)
        return if @redis.hget(feature, category).to_i < 1
        @redis.hdecrby(feature, category, 1)
      end

      def decrement_item_count_in_category(category)
        return unless @redis.exists(category)
        return if @redis.get(category).to_i < 1
        @redis.decr(category)
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
        return 0 unless @redis.exists(feature)
        return 0 unless @redis.hexists(feature, category)
        return 0 if @redis.get(category).to_i == 0
        @redis.hget(feature, category).to_f / @redis.get(category).to_i
      end

      def calculate_category_probability(category)
        @redis.get(category).to_f / total_feature_count
      end

      def total_feature_count
        CATEGORIES.inject(0) do |count, category|
          count += @redis.get(category).to_i
        end
      end
    end
  end
end
