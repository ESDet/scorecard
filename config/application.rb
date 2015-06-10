require File.expand_path('../boot', __FILE__)

require 'sprockets/railtie'
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

Bundler.require(:default, Rails.env) if defined?(Bundler)

if Rails.env == :development || Rails.env == :test
  require 'dotenv'
  Dotenv.load
end

module ESD
  class Application < Rails::Application

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    config.time_zone = 'Eastern Time (US & Canada)'

    # JavaScript files you want as :defaults (application.js is always included).
    config.encoding = "utf-8"
    config.filter_parameters += [:password]

    config.generators do |g|
      g.template_engine :haml
    end

    config.secret_key_base = Rails.application.secrets.secret_key_base
  end
end
