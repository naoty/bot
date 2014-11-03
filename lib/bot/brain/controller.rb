require "resque"
require "twitter"

module Bot
  module Brain
    class Controller
      def initialize
        @bot = Actuator::Bot.new
        @classifier = Classifier.new
        @notifier = Notifier.new
      end

      def control_human_input(object)
        case object
        when Twitter::Tweet
          control_human_timeline(object)
        when Twitter::Streaming::Event
          control_human_favorite(object) if object.name == :favorite
        end
      end

      def control_bot_input(object)
        case object
        when Twitter::Tweet
         control_bot_timeline(object)
        end
      end

      private

      def control_human_timeline(tweet)
        screen_name = tweet.user.screen_name
        tweet_text = tweet.text
        Resque.enqueue(TrainingJob, screen_name, tweet_text, :normal)
      end

      def control_human_favorite(tweet)
        screen_name = tweet.target_object.user.screen_name
        tweet_text = tweet.target_object.text
        Resque.enqueue(TrainingJob, screen_name, tweet_text, :favorite)
      end

      def control_bot_timeline(tweet)
        screen_name = tweet.user.screen_name
        text = tweet.text
        case @classifier.classify(screen_name, text)
        when :favorite
          @notifier.notify(title: "Favorite", message: "#{screen_name}: #{text}")
          @bot.favorite(tweet)
        end
      end
    end
  end
end