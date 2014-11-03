require "twitter"

module Bot
  module Brain
    class Trainer
      def initialize
        @client = Twitter::REST::Client.new do |config|
          config.consumer_key = ENV["CONSUMER_KEY"]
          config.consumer_secret = ENV["CONSUMER_SECRET"]
          config.access_token = ENV["TARGET_ACCESS_TOKEN"]
          config.access_token_secret = ENV["TARGET_ACCESS_TOKEN_SECRET"]
        end
        @classifier = Classifier.new
        @favorite_ids = []
      end

      def activate
        train_favorites
        train_normals
      end

      private

      def train_favorites
        options = { count: 100 }
        8.times do
          favorites = @client.favorites(options)
          favorites.each do |tweet|
            @classifier.train(tweet.user.screen_name, tweet.text, :favorite)
            @favorite_ids << tweet.id
          end
          options[:max_id] = favorites.last.id - 1
        end
      end

      def train_normals
        options = { count: 100 }
        8.times do
          tweets = @client.home_timeline(options)
          tweets.each do |tweet|
            next if @favorite_ids.include?(tweet.id)
            @classifier.train(tweet.user.screen_name, tweet.text, :normal)
          end
          options[:max_id] = tweets.last.id - 1
        end
      end
    end
  end
end
