module Bedrock
  class GeoController < ApplicationController
    include Bedrock::TileHelper

    def geocode
      opts = {}
      opts[:bounds] = params[:extent] if params[:extent]
      result = Geocoder.geocode(params[:address])
      render :json => result
    end
    
    def autocomplete
      # TODO: use config to find what table/query
      # elements = Thing.where(['propaddres like ?', params[:address]])
      render :json => {
        :query => params[:address]
      }
    end
    
    def disable_gps
      session[:gps_disabled] = true
      render :text => 'Ok'
    end
    
    def enable_gps
      session[:gps_disabled] = false
      render :text => 'Ok'
    end
    
  end
end
