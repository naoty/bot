require "thor"

module Bot
  module Command
    module Subcommand
      class Sensor < Thor
        desc "human", "Activate human sensor"
        def human
          Bot::Sensor::Human.new.activate
          trap(:INT) do
            puts "\nExit."
            exit
          end
        end

        desc "bot", "Activate bot sensor"
        def bot
          Bot::Sensor::Bot.new.activate
          trap(:INT) do
            puts "\nExit."
            exit
          end
        end
      end
    end

    class Activator < Thor
      desc "sensor", "Activate sensors"
      subcommand "sensor", Subcommand::Sensor

      desc "trainer", "Activate trainer"
      def trainer
        Trainer.new.activate
      end
    end
  end
end
