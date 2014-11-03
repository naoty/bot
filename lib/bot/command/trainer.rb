require "thor"

module Bot
  module Command
    class Trainer < Thor
      desc "classifier", "Train classifier"
      def classifier
        Brain::Trainer.new.train_classifier
      end

      desc "biorythm", "Train biorythm"
      def biorythm
        Brain::Trainer.new.train_biorythm
      end
    end
  end
end