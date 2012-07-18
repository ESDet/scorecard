require File.expand_path('../boot', __FILE__)

ENV['RAILS_ENV'] = 'staging'

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module ESD
  class Application < Rails::Application

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    config.time_zone = 'Eastern Time (US & Canada)'

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w()
    config.encoding = "utf-8"
    config.filter_parameters += [:password]

    config.generators do |g|
      g.template_engine :haml
    end    

  end
end
