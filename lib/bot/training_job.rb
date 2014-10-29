module Bot
  class TrainingJob
    @queue = :training
    @classifier = Classifier.new

    def self.perform(text, category)
      @classifier.train(text, category)
    end
  end
end
