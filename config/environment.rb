# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

# Brevo SMTP configuration
ActionMailer::Base.smtp_settings = {
  address: 'smtp-relay.brevo.com',
  port: 587,
  authentication: :plain,
  user_name: Rails.application.credentials.dig(:brevo, :smtp_login),
  password: Rails.application.credentials.dig(:brevo, :smtp_key),
  enable_starttls_auto: true
}