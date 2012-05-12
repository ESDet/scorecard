ESD::Application.configure do

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

  config.action_mailer.default_url_options = { :host => "esd.makeloveland.com" }

  config.middleware.use ExceptionNotifier,
    :email_prefix => "[ESD staging] ",
    :sender_address => %{"Exception Notifier" <info@makeloveland.com>},
    :exception_recipients => %w{larry@makeloveland.com}

end
