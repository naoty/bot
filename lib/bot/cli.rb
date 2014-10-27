require "thor"

module Bot
  class CLI < Thor
    desc "start", "Start bot"
    def start
      trap(:INT) do
        puts "\nExit."
        exit
      end
      Client.new.start
    end
  end
end
