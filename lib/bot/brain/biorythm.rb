require "redis"

module Bot
  module Brain
    class Biorythm
      COUNT_KEY = "bot:tweet_counts"
      TOTAL_COUNT_KEY = "bot:total_tweet_count"
      TWEET_INTERVAL_IN_SECOND = 1 * 60
      MIN_TWEET_COUNT_PER_DAY = 15
      MAX_TWEET_COUNT_PER_DAY = 30

      def initialize
        @threads = []
        @bot = Actuator::Bot.new
        @notifier = Notifier.new
        @redis = Redis.new
      end

      def activate
        @notifier.notify(title: "Bot::Brain::Biorythm", message: "activate")

        determine_schedule!
        activate_schedule_update
        activate_scheduled_tweets
        @threads.each { |thread| thread.join }
      end

      def setup_training
        # minutes per day
        1440.times { |minute| @redis.hset(COUNT_KEY, minute, 0) }
      end

      def train(datetime)
        minute = datetime.hour * 60 + datetime.min
        increment_tweet_count(minute)
        increment_total_tweet_count
      end

      private

      def determine_schedule!
        @scheduled_minutes = []

        tweet_count_per_day = (MIN_TWEET_COUNT_PER_DAY..MAX_TWEET_COUNT_PER_DAY).to_a.sample
        accumulated_probabilities = calculate_accumulated_probabilities
        tweet_count_per_day.times do
          r = rand
          minute = accumulated_probabilities.index { |p| p > r }
          @scheduled_minutes << minute
          accumulated_probabilities.delete_at(minute)
        end
      end

      def calculate_accumulated_probabilities
        minute_and_probability = {}
        total_count = @redis.get(TOTAL_COUNT_KEY).to_i
        @redis.hgetall(COUNT_KEY).each do |minute, count|
          minute_and_probability[minute.to_i] = count.to_f / total_count
        end
        probabilities = minute_and_probability.sort.map(&:last)

        previous_probability = 0
        probabilities.map { |p| previous_probability += p }
      end

      def activate_schedule_update
        @threads << Thread.new do
          loop do
            sleep(1 * 24 * 60 * 60) # 1 day
            determine_schedule!
          end
        end
      end

      def activate_scheduled_tweets
        @threads << Thread.new do
          loop do
            @bot.tweet("tweet test") if on_time?
            sleep(TWEET_INTERVAL_IN_SECOND)
          end
        end
      end

      def on_time?
        now = Time.now
        minute = now.hour * 60 + now.min
        @scheduled_minutes.include?(minute)
      end

      def increment_tweet_count(minute)
        @redis.hincrby(COUNT_KEY, minute, 1)
      end

      def increment_total_tweet_count
        @redis.set(TOTAL_COUNT_KEY, 0) unless @redis.exists(TOTAL_COUNT_KEY)
        @redis.incr(TOTAL_COUNT_KEY)
      end

      def tweet_probability
        now = Time.now
        minute = now.hour * 60 + now.min
        tweet_count_at_minute = @redis.hget(COUNT_KEY, minute).to_i
        total_tweet_count = @redis.hget(COUNT_KEY, "total").to_i
        total_tweet_count > 0 ? tweet_count_at_minute.to_f / total_tweet_count : 0
      end
    end
  end
end