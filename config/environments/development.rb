ESD::Application.configure do
  config.cache_classes = false
  config.whiny_nils = true
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log
  config.action_dispatch.best_standards_support = :builtin
  config.eager_load = false
  config.assets.debug = true
  config.cache_store = :null_store

  #
  # uncomment to test caching in development mode
  #
  #config.consider_all_requests_local       = false
  #config.action_controller.perform_caching = true
  #config.cache_store = :dalli_store, ('127.0.0.1'), {
  #  :namespace => 'scorecard',
  #  :expires_in => 3600,
  #  :compress => true
  #}
end

