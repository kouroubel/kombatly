# Move this require to your `config/application.rb` if you want to be notified from runner commands too.
require "exception_notification/rails"
require "exception_notification/rake"


ExceptionNotification.configure do |config|

  # Notifiers =================================================================

  # Email notifier sends notifications by email.
  config.add_notifier :email, {
    email_prefix: "[ERROR] ",
    sender_address: %("Kombatly Errors" <noreply@teamlink.gr>),
    exception_recipients: %w{albert.roussos@gmail.com},
    sections: %w{request backtrace session}
  }

end
