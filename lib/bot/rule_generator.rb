require "okura/serializer"

module Bot
  class RuleGenerator
    def initialize
      dictionary_path = File.expand_path("../../assets/okura-dic", __dir__)
      @tagger = Okura::Serializer::FormatInfo.create_tagger(dictionary_path)
    end

    def generate(text)
      nodes = @tagger.parse(text)
      words = nodes.mincost_path.map(&:word)
      words = words.select { |word| word.left.text =~ /名詞/ }
      keywords = words.map(&:surface)
      return if keywords.empty?

      FavoriteRule.create(keywords)
    end
  end
end
