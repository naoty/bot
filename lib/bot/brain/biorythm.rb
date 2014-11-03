require "redis"

module Bot
  module Brain
    class Biorythm
      KEY = "tweet_counts"
      INTERVAL_IN_SECOND = 1 * 60

      def initialize
        @bot = Actuator::Bot.new
        @notifier = Notifier.new
        @redis = Redis.new
      end

      def activate
        @notifier.notify(title: "Bot::Brain::Biorythm", message: "activate")
        loop do
          if tweet_probability >= rand
            @bot.tweet("tweet test")
          end
          sleep(INTERVAL_IN_SECOND)
        end
      end

      def train(datetime)
        minute = datetime.hour * 60 + datetime.min
        if !@redis.exists(KEY) || !@redis.hexists(KEY, minute)
          @redis.hset(KEY, minute, 0)
        end
        @redis.hincrby(KEY, minute, 1)

        if !@redis.exists(KEY) || !@redis.hexists(KEY, "total")
          @redis.hset(KEY, "total", 0)
        end
        @redis.hincrby(KEY, "total", 1)
      end

      private

      def tweet_probability
        now = Time.now
        minute = now.hour * 60 + now.min
        tweet_count_at_minute = @redis.hget(KEY, minute).to_i
        total_tweet_count = @redis.hget(KEY, "total").to_i
        total_tweet_count > 0 ? tweet_count_at_minute.to_f / total_tweet_count : 0
      end
    end
  end
end