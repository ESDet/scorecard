module Bedrock
  class Engine < Rails::Engine

    initializer "bedrock.static_assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
    
    initializer "bedrock.defaults" do |app|
      Bedrock.setup do |config|
        config.cloudmade_style ||= '998'
        config.cloudmade_key   ||= '194e5888480d4f9499b2f2099a793dbe'
        config.default_city    ||= 'Detroit'
        config.default_state   ||= 'MI'
      end
    end
    
    initializer "bedrock.load_config" do |app|
      require 'ostruct'
      require 'yaml'
      begin
        Bedrock.config_hash = YAML.load_file("#{Rails.root.to_s}/config/bedrock.yml") || {}
        Bedrock.setup do |config|
          Bedrock.config_hash.each do |k,v|
            begin; config.send("#{k}=", v); rescue; end
          end
        end
      rescue => e
        #logger.info "Could not load bedrock.yml"
      end
  
    end
  end
end
