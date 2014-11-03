require "twitter"

module Bot
  module Actuator
    class Bot
      def initialize
        @client = Twitter::REST::Client.new do |config|
          config.consumer_key = ENV["CONSUMER_KEY"]
          config.consumer_secret = ENV["CONSUMER_SECRET"]
          config.access_token = ENV["BOT_ACCESS_TOKEN"]
          config.access_token_secret = ENV["BOT_ACCESS_TOKEN_SECRET"]
        end
      end

      def favorite(tweet)
        @client.favorite(tweet)
      end
    end
  end
end