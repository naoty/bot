require "twitter"

module Bot
  module Sensor
    class Bot
      def initialize
        @client = Twitter::Streaming::Client.new do |config|
          config.consumer_key = ENV["CONSUMER_KEY"]
          config.consumer_secret = ENV["CONSUMER_SECRET"]
          config.access_token = ENV["BOT_ACCESS_TOKEN"]
          config.access_token_secret = ENV["BOT_ACCESS_TOKEN_SECRET"]
        end
        @notifier = Notifier.new
        @controller = Brain::Controller.new
      end

      def activate
        @notifier.notify(title: "Bot::Sensor::Bot", message: "activate")
        @client.user do |object|
          @controller.control_bot_input(object)
        end
      end
    end
  end
end