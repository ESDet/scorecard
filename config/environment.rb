# Load the rails application
require File.expand_path('../application', __FILE__)

ActionMailer::Base.smtp_settings = {
  :user_name            => ENV['SMTP_USER'],
  :password             => ENV['SMTP_PASS'],
  :domain               => ENV['SMTP_DOMAIN'],
  :address              => ENV['SMTP_ADDRESS'],
  :port                 => ENV['SMTP_PORT'],
  :authentication       => :plain,
  :enable_starttls_auto => true
}

# Initialize the rails application
ESD::Application.initialize!
