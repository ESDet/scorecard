require 'ostruct'
 
class OpenStruct
  def as_json(options = nil)
    @table.as_json(options)
  end

  DEPTH = 5
  def self.deep(data, depth=0, &blck)
    return data if depth > DEPTH
    return data unless data.class == Hash
    hash = {}
    data.each do |key, value|
      key = blck.call(key) if block_given?
      case value
      when Hash
        hash[key] = OpenStruct.deep(value, depth + 1, &blck)
      when Array
        hash[key] = value.map{ |element| OpenStruct.deep(element, depth + 1, &blck) }
      else
        hash[key] = value
      end
    end
    OpenStruct.new(hash)
  end
end