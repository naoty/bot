require "pathname"

module Bot
  def self.root_path
    Pathname.new("..").expand_path(__dir__)
  end
end

require "bot/actuator/bot"
require "bot/brain/biorythm"
require "bot/brain/classifier"
require "bot/brain/controller"
require "bot/brain/corpus"
require "bot/brain/trainer"
require "bot/brain/training_job"
require "bot/command/activator"
require "bot/command/trainer"
require "bot/notifier"
require "bot/sensor/bot"
require "bot/sensor/human"
