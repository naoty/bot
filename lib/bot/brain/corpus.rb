require "mysql2"
require "okura/serializer"
require "socket"

module Bot
  module Brain
    class Corpus
      NAMESPACE = "bot:tweets"
      SYNONYM_REPLACE_PATTERN = /名詞/
      SAMPLE_MINUTE_RANGE = 30

      def initialize
        dictionary_path = Bot.root_path.join("assets/okura-dic").to_s
        @tagger = Okura::Serializer::FormatInfo.create_tagger(dictionary_path)
        @mysql = Mysql2::Client.new(
          username: ENV["MYSQL_USERNAME"],
          password: ENV["MYSQL_PASSWORD"],
          database: ENV["MYSQL_DATABASE"]
        )
      end

      def generate_text
        nodes = @tagger.parse(sample_text)
        words = nodes.mincost_path.map do |node|
          surface = node.word.surface
          node.word.left.text =~ SYNONYM_REPLACE_PATTERN ? request_synonym(surface) : surface
        end
        words.delete("BOS/EOS")
        words.join
      end

      def train(id, text, datetime)
        minute = datetime.hour * 60 + datetime.min
        values = [id, "'#{@mysql.escape(text)}'", minute].join(", ")
        begin
          @mysql.query("INSERT INTO tweets (tweet_id, text, minute) VALUES (#{values})")
        rescue
        end
      end

      private

      def sample_text
        now = Time.now
        minute = now.hour * 60 + now.min
        min_minute = minute - SAMPLE_MINUTE_RANGE * 60
        max_minute = minute + SAMPLE_MINUTE_RANGE * 60

        tweets = @mysql.query("SELECT * FROM tweets WHERE minute BETWEEN #{min_minute} AND #{max_minute}")
        tweets.to_a.sample["text"]
      end

      def request_synonym(word)
        socket_path = Bot.root_path.join("synonym.sock").to_s
        UNIXSocket.open(socket_path) do |socket|
          socket.send(word, 0)
          response = socket.recvmsg
          return response[0].force_encoding("utf-8")
        end
      end
    end
  end
end
