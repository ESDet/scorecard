ESD::Application.configure do

  config.eager_load = true
  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  # config.log_level = :debug

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store
  config.serve_static_assets = false
  # config.action_controller.asset_host = "http://assets.example.com"
  # config.action_mailer.raise_delivery_errors = false
  # config.threadsafe!
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  config.cache_store = :dalli_store, (ENV['MEMCACHE_HOST'] || '127.0.0.1'), {
    :namespace => ENV['MEMCACHE_NAMESPACE'],
    :username => ENV['MEMCACHE_USER'],
    :password => ENV['MEMCACHE_PASS'],
    :expires_in => 3600,
    :compress => true
  }

  ActionMailer::Base.delivery_method = :smtp

  config.action_mailer.default_url_options = { :host => ENV['SMTP_DOMAIN'] }

  Rails.application.config.middleware.use ExceptionNotification::Rack,
    email: {
      :email_prefix => "#{ENV['EMAIL_PREFIX']} ",
      :sender_address => %{"Exception Notifier" <noreply@alfajango.com>},
      :exception_recipients => %w{excellentschools@alfajango.com}
    }
end
