require "pushover"

Pushover.configure do |config|
  config.user = ENV["PUSHOVER_USER_TOKEN"]
  config.token = ENV["PUSHOVER_APPLICATION_TOKEN"]
end

module Bot
  class Notifier
    def notify(title: "", message: "")
      Pushover.notification(message: message, title: title)
    end
  end
end
