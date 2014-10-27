require "twitter"

module Bot
  class Client
    def initialize
      @client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.access_token = ENV["ACCESS_TOKEN"]
        config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      end
    end

    def start
      @client.user do |object|
        case object
        when Twitter::Streaming::Event
          # TODO: Process events
        end
      end
    end
  end
end
