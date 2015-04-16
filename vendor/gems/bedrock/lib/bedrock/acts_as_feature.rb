module Bedrock
  module ActsAsFeature
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_feature(options = {})
        cattr_accessor :geometry_column, :index, :fields, :add_properties, :proj
        self.geometry_column   = options[:geometry]
        self.index             = options[:index]
        self.fields            = options[:fields].collect { |f| f.to_s }
        self.add_properties    = options[:add_properties]
        self.proj              = options[:proj]
        set_rgeo_factory_for_column(self.geometry_column, RGeo::Geographic.projected_factory(:projection_proj4 => self.proj)) if self.proj
        throw "Must specificy :geometry" unless self.geometry_column

        scope :inside, lambda { |thing, opts={}| inside_new(thing, opts) }
      end


      # available opts: :poly, :limit, :order, :select, :index, :include, :geometry_column, :conditions
      def inside_old(ext, opts = {})
        s, w, n, e = [ext[0][:lat], ext[0][:lon], ext[1][:lat], ext[1][:lon]]
        from = self.table_name
        idx = opts[:index] || index
        from += " use index(#{idx})" unless idx.blank?
        gc = opts[:geometry_column] || self.geometry_column
        conditions = ["MBRIntersects(GeomFromText('LineString(? ?, ? ?)'), #{gc})", w, s, e, n ]
        h = { :conditions => conditions, :limit => (opts[:limit] || 4000) }
        h[:order] = opts[:order] if opts[:order]
        h[:select] = opts[:select] if opts[:select]
        #::Rails.logger.info "inside: h=#{h.inspect}"
        #h[:select] += ",#{self.geometry_column.to_s}" unless h[:select].nil? or h[:select].include?(self.geometry_column.to_s)
        h[:select] += ",#{gc.to_s}" unless h[:select].nil? or h[:select].include?(gc.to_s)
        #::Rails.logger.info "inside after adding gc (#{gc.to_s}): h=#{h.inspect}"
        h[:include] = opts[:include] if opts[:include]
        if opts[:conditions]
          result = self.from(from).where(opts[:conditions]).all(h)
        else
          result = self.from(from).all(h)
        end

        if opts[:poly]
          #result = result.select { |p| p.send(gc).intersects? opts[:poly] }
          result = result.select { |p| opts[:poly].contains?(p.send(gc)) }
        end

        return result
      end

      # Now that we have proper spatial queries this is simpler
      def inside_new(geom, opts = {})
        geom  = geom.geometry if defined?(geom.geometry) # unless geom.is_a?(RGeo::Feature::Geometry)
        gc    = opts[:geometry_column]  || self.geometry_column
        idx   = opts[:index]            || self.index
        from  = idx.blank? ? table_name : "`#{table_name}` use index(#{idx})"

        # Possible WKB for later: bin = geom.as_binary; hex = bin.unpack("H#{bin.length*2}")

        method = (opts[:method] == :intersects) ? 'ST_Intersects' : 'ST_Contains'
        q = self.from(from).where(["#{method}(GeometryFromText(?), `#{table_name}`.#{gc})", geom.as_text])

        opts[:select] += ",#{gc.to_s}" unless opts[:select].blank? or opts[:select].include?(gc.to_s)

        q = q.where(opts[:conditions])  if opts[:conditions]
        q = q.select(opts[:select])     if opts[:select]
        q = q.limit(opts[:limit])       if opts[:limit]
        q = q.includes(opts[:include])  if opts[:include]
        q = q.order(opts[:order])       if opts[:order]

        q
      end


      #def inside(thing, opts = {})
        # Old way using [ { lat, lon } { lat, lon } ] as the query extent
        # vs new way where thing is actually a geometry
        #thing.is_a?(Array) ? inside_old(thing, opts) : inside_new(thing, opts)
      #end
    end


    def geometry
      self.send(self.geometry_column)
    end

    def to_feature
      shape = self[self.class.geometry_column]
      properties = self.fields ? self.attributes.from_keys(self.fields) : self.attributes
      properties.merge!(self.send(self.add_properties)) if self.add_properties
      result = RGeo::GeoJSON::Feature.new(shape, self.id, properties)
      return result
    end

    def envelope
      query = "select AsText(Envelope(#{self.class.geometry_column})) from #{self.class.table_name} where #{self.class.primary_key} = #{self.id};"
      row = self.class.connection.select_rows query
      RGeo::Geographic.spherical_factory.parse_wkt row[0][0]
    end

    def extent
      ext = Bedrock::extent(self.envelope)
      return ext unless ext.nil?

      # You must be a point
      sh = self.geometry
      return [ { :lon => sh.x, :lat => sh.y }, { :lon => sh.x, :lat => sh.y } ]
    end

  end
end

class Hash
  def from_keys(keys)
    keys.inject({}) { |h,k| h[k] = self[k] if has_key?(k); h }
  end
end

ActiveRecord::Base.send :include, Bedrock::ActsAsFeature
