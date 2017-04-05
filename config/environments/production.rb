ESD::Application.configure do

  config.eager_load = true
  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.serve_static_files = false
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  config.cache_store = :dalli_store,
    (ENV["MEMCACHIER_SERVERS"] || "").split(","),
    {:username => ENV["MEMCACHIER_USERNAME"],
     :password => ENV["MEMCACHIER_PASSWORD"],
     :failover => true,
     :socket_timeout => 1.5,
     :socket_failure_delay => 0.2,
     :pool_size => (ENV["MAX_THREADS"] || 3)
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
