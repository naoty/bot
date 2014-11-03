require "twitter"

module Bot
  module Sensor
    class Human
      def initialize
        @client = Twitter::Streaming::Client.new do |config|
          config.consumer_key = ENV["CONSUMER_KEY"]
          config.consumer_secret = ENV["CONSUMER_SECRET"]
          config.access_token = ENV["HUMAN_ACCESS_TOKEN"]
          config.access_token_secret = ENV["HUMAN_ACCESS_TOKEN_SECRET"]
        end

        rest_client = Twitter::REST::Client.new do |config|
          config.consumer_key = ENV["CONSUMER_KEY"]
          config.consumer_secret = ENV["CONSUMER_SECRET"]
          config.access_token = ENV["HUMAN_ACCESS_TOKEN"]
          config.access_token_secret = ENV["HUMAN_ACCESS_TOKEN_SECRET"]
        end
        @user = rest_client.user({ skip_status: true })

        @notifier = Notifier.new
        @controller = Brain::Controller.new
      end

      def activate
        @notifier.notify(title: "Bot::Sensor::Human", message: "activate")
        @client.user do |object|
          @controller.control_human_input(@user.id, object)
        end
      end
    end
  end
end