module Bot
  class TrainingJob
    @queue = :training
    @classifier = Classifier.new

    def self.perform(screen_name, text, category)
      @classifier.train(screen_name, text, category)
    end
  end
end
