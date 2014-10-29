require "thor"

module Bot
  class Start < Thor
    desc "observer", "Start observer"
    def observer
      Observer.new.start
      trap(:INT) do
        puts "\nObserver exit."
        exit
      end
    end

    desc "emulator", "Start emulator"
    def emulator
      Emulator.new.start
      trap(:INT) do
        puts "\nEmulator exit."
        exit
      end
    end
  end

  class CLI < Thor
    desc "start", "Start bot"
    subcommand "start", Start
  end
end
