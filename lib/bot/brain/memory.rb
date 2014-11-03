require "redis"

module Bot
  module Brain
    class Memory
      KEY = "tweets"

      def initialize
        @redis = Redis.new
      end

      def save(id, text, datetime)
        @redis.hset("#{KEY}:#{id}", "text", text)
        @redis.hset("#{KEY}:#{id}", "created_at", datetime)
      end
    end
  end
end