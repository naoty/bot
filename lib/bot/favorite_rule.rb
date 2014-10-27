module Bot
  class FavoriteRule
    def self.create(keywords)
      self.new(keywords).save
    end

    def initialize(keywords)
      @keywords = keywords
    end

    def save
      # TODO: Save rules into database
      puts %(Rule "#{@keywords.join(", ")} -> Fav" saved!)
    end
  end
end
