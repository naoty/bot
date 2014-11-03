require "thor"

module Bot
  module Command
    module Subcommand
      class Sensor < Thor
        desc "human", "Activate human sensor"
        def human
          trap(:INT) do
            puts "\nExit."
            exit
          end
          Bot::Sensor::Human.new.activate
        end

        desc "bot", "Activate bot sensor"
        def bot
          trap(:INT) do
            puts "\nExit."
            exit
          end
          Bot::Sensor::Bot.new.activate
        end
      end
    end

    class Activator < Thor
      desc "sensor", "Activate sensors"
      subcommand "sensor", Subcommand::Sensor

      desc "biorythm", "Activate biorythm"
      def biorythm
        trap(:INT) do
          puts "\nExit."
          exit
        end
        Brain::Biorythm.new.activate
      end
    end
  end
end
