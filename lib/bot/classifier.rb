require "okura/serializer"

module Bot
  class Classifier
    CATEGORY_THRESHOLD = 3

    def initialize
      dictionary_path = File.expand_path("../../assets/okura-dic", __dir__)
      @tagger = Okura::Serializer::FormatInfo.create_tagger(dictionary_path)
      @item_count_in_feature_and_category = {}
      @item_count_in_category = {}
    end

    def train(text, category)
      puts "Train: #{text} -> #{category}"
      features = parse(text)
      features.each do |feature|
        increment_item_count_in_feature_and_category(feature, category)
        increment_item_count_in_category(category)
        if category == :favorite
          decrement_item_count_in_feature_and_category(feature, :normal)
          decrement_item_count_in_category(:normal)
        end
      end
    end

    def classify(text)
      favorite_probability = calculate_probability(text, :favorite)
      not_favorite_probability = calculate_probability(text, :not_favorite)
      (favorite_probability > not_favorite_probability * CATEGORY_THRESHOLD) ? :favorite : :not_favorite
    end

    private

    def parse(text)
      nodes = @tagger.parse(text)
      nodes.mincost_path.map { |node| node.word.surface }.uniq
    end

    def increment_item_count_in_feature_and_category(feature, category)
      @item_count_in_feature_and_category[feature] ||= {}
      @item_count_in_feature_and_category[feature][category] ||= 0
      @item_count_in_feature_and_category[feature][category] += 1
    end

    def increment_item_count_in_category(category)
      @item_count_in_category[category] ||= 0
      @item_count_in_category[category] += 1
    end

    def decrement_item_count_in_feature_and_category(feature, category)
      return if @item_count_in_feature_and_category[feature].nil?
      return if @item_count_in_feature_and_category[feature][category].nil?
      return if @item_count_in_feature_and_category[feature][category] < 1
      @item_count_in_feature_and_category[feature][category] -= 1
    end

    def decrement_item_count_in_category(category)
      return if @item_count_in_category[category].nil?
      return if @item_count_in_category[category] < 1
      @item_count_in_category[category] -= 1
    end

    def calculate_probability(text, category)
      features = parse(text)
      cumulated_probability = features.reduce(1) do |probability, feature|
        probability *= calculate_feature_probability(feature, category)
      end
      category_probability = calculate_category_probability(category)
      cumulated_probability * category_probability
    end

    def calculate_feature_probability(feature, category)
      return 0 if @item_count_in_feature_and_category[feature].nil?
      return 0 if @item_count_in_feature_and_category[feature][category].nil?
      return 0 if @item_count_in_category[category] == 0

      @item_count_in_feature_and_category[feature][category].to_f / @item_count_in_category[category]
    end

    def calculate_category_probability(category)
      @item_count_in_category[category].to_f / total_feature_count
    end

    def total_feature_count
      @item_count_in_category.values.inject(&:+)
    end
  end
end
