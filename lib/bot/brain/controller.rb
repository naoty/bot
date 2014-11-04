require "resque"
require "twitter"

module Bot
  module Brain
    class Controller
      def initialize
        @biorythm = Biorythm.new
        @bot = Actuator::Bot.new
        @classifier = Classifier.new
        @memory = Memory.new
      end

      def control_human_input(user_id, object)
        case object
        when Twitter::Tweet
          control_human_timeline(object)
          control_human_tweet(object) if user_id == object.user.id
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

      def control_human_tweet(tweet)
        @biorythm.train(tweet.created_at)
        @memory.save(tweet.id, tweet.text, tweet.created_at)
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
          @bot.favorite(tweet)
        end
      end
    end
  end
end
