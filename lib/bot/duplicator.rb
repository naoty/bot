require "twitter"

module Bot
  class Duplicator
    def initialize
      @client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.access_token = ENV["ACCESS_TOKEN"]
        config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      end
      @rule_generator = RuleGenerator.new
    end

    def start
      @client.user do |object|
        case object
        when Twitter::Streaming::Event
          if object.name == :favorite
            tweet_text = object.target_object.text
            @rule_generator.generate(tweet_text)
          end
        end
      end
    end
  end
end
