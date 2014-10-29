require "twitter"

module Bot
  class Emulator
    def initialize
      @watcher = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.access_token = ENV["ACCESS_TOKEN"]
        config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      end
      @actor = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.access_token = ENV["ACCESS_TOKEN"]
        config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      end
      @classifier = Classifier.new
    end

    def start
      @watcher.user do |object|
        case object
        when Twitter::Tweet
          screen_name = object.user.screen_name
          text = object.text
          case @classifier.classify(screen_name, text)
          when :favorite
            puts "[FAVORITE] #{screen_name}: #{text}"
            @actor.favorite(object)
          end
        end
      end
    end
  end
end
