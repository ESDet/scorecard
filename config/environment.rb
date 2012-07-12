# Load the rails application
require File.expand_path('../application', __FILE__)

ActionMailer::Base.smtp_settings = {
  :user_name            => "lsheradon",
  :password             => "gem17years",
  :domain               => 'makeloveland.com',
  :address              => "smtp.sendgrid.net",
  :port                 => 587,
  :authentication       => :plain,
  :enable_starttls_auto => true
}

Miley.setup do |s|
  s.host = '127.0.0.1'
  s.appname = 'esd'
end

# Initialize the rails application
ESD::Application.initialize!
