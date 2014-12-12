module Bedrock
  class Geocoder

    def self.geocode(natural, options = {})
      # options: :address, :city, :state, :zip, :base
      require 'net/http'

      # cases:
      #  natural only
      #    with just an address
      #    with address, city/state/zip combo
      #  natural with options?? maybe not!
      #  options only - combine address, city/state/zip into a full string
      
      return { :location => {:lat => 0, :lon => 0} } if natural.blank? and options.empty?
      
      if options.empty? or (options.size==1 and options[:base])
        query = natural
        query += ", detroit mi" unless natural.downcase.include?(',')
      elsif options[:city] or options[:zip]
        query = "#{options[:address]}, #{options[:city]} #{options[:state]} #{options[:zip]}"
      else
        # might have given :bounds as a hint
        query = natural
      end
      
      opts = {
        :address => query,
        :bounds => "42.25553701670208,-83.30549041410507%7C42.45154726014215,-82.89437334943926",
        :sensor => "false"
      }
      b = options[:bounds]
      opts[:bounds] = "#{b[0][:lat]},#{b[0][:lon]}%7C#{b[1][:lat]},#{b[1][:lon]}" if b
      
      opts[:components] = "administrative_area:#{options[:state]}" if options[:state]
      
      base = options[:base] || "http://maps.googleapis.com"
      url = URI.parse "#{base}/maps/api/geocode/json?#{opts.to_query}"
      puts opts.inspect
      Rails.logger.info url
      Rails.logger.info opts.inspect
      response = Net::HTTP.get(url)
      body = nil
      begin
        body = JSON.parse response
      rescue
        return nil
      end
      
      if body.nil? or body['results'].blank?
        puts "Oops!"
        puts body.inspect
        return nil
      else
        geom = body['results'][0]['geometry']
        lat = geom['location']['lat']
        lng = geom['location']['lng']
        sw  = geom['viewport']['southwest']
        ne  = geom['viewport']['northeast']
        extent = [ { :lat => sw['lat'], :lon => sw['lng'] }, { :lat => ne['lat'], :lon => ne['lng'] } ]
        
        #puts body.inspect
        ac = body['results'][0]['address_components']
        zc = ac.select { |c| c['types'][0] == 'postal_code' }
        zip = zc.andand[0].andand['short_name']
        
        return { :location => { :lat => lat, :lon => lng }, :extent => extent, :zip => zip }
      end
    end 
    
    
    def self.bing_geocode(opts)
      require 'net/http'
      # http://dev.virtualearth.net/REST/v1/Locations/US/MI/48216/detroit/9197%20abington?maxResults=10&key=AtX0UxXkWS3Ww0h73R-sHuB1_qQWvq28PrA9vsxG9HQyNBOTO3_cqfoBPZwfvJvf
      
      # opts: :address, :city, :state, :zip
      
      key = "AtX0UxXkWS3Ww0h73R-sHuB1_qQWvq28PrA9vsxG9HQyNBOTO3_cqfoBPZwfvJvf"
      address = opts[:address].gsub(/[^A-z0-9 ]/, '')
      city    = opts[:city]
      zip     = opts[:zip]
      state   = opts[:state]
      
      frag = URI.encode "#{state}/#{zip}/#{city}/#{address.gsub('.', '')}"
      url = URI.parse "http://dev.virtualearth.net/REST/v1/Locations/US/#{frag}?maxResults=10&key=#{key}"
      puts url
      response = Net::HTTP.get(url)
      begin
        body = JSON.parse response
      rescue
        # Sometimes you get back an HTML response
        return nil
      end
      
      if body['resourceSets'].andand.first.andand['resources'].andand.first.andand['point'].andand['coordinates']
        puts body.inspect
        coords = body['resourceSets'].first['resources'].first['point']['coordinates']
        return { :location => { :lat => coords[0], :lon => coords[1] }  }
      else
        puts "Oops!"
        puts body.inspect
        return nil
      end
      
    end
    
    
    #@@modes = { Tour::WALKING => 'walking', Tour::DRIVING => 'driving', Tour::BIKING => 'bicycling' }
    #  places = tour.places.reject { |p| p.address.blank? or (p.location.x == 0 and p.location.y == 0) }
    #  points = tour.places.collect { |p| p.location }
    def self.directions(points, mode = 'driving')
      #addresses = tour.places.collect { |p| p.address }
      return nil if points.length < 2 # TODO, format it better ok?
      
      routes = []
      # We get 8 waypoints, so gotta divvy up the trip into parts
      # - Subsequent slices need to start with the last pt of the previous
      # - Don't allow sequences of only one
      ranges = []
      chunk_len = 9
      (points.length / chunk_len.to_f).ceil.times do |i|
        n = i * chunk_len
        ranges << (i*chunk_len..(i+1)*chunk_len)
      end
      puts ranges.inspect
      ranges.each do |range|
        slice = points.slice range
        puts slice.inspect
        opts = {
          :sensor       => false,
          :mode         => mode,
          :origin       => to_gll(slice[0]),
          :destination  => to_gll(slice[-1]),
          :waypoints    => slice[1...-1].collect { |p| to_gll(p) }.join('|')
        }
        puts opts.inspect
        url = URI.parse "http://maps.googleapis.com/maps/api/directions/json?#{opts.to_query}"
        puts url
        response = Net::HTTP.get(url)
        body = JSON.parse response
        if body['status'] != 'OK'
          puts "Oops! #{body.inspect}"
          return nil
        end
        routes << body['routes'].first
      end
      
      return routes
    end
    
    
    protected
    
    def self.to_gll(point)
      "#{point.y},#{point.x}"
    end
    
  end
end