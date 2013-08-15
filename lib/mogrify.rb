module Mogrify

  def self.transliterate(str)
    return nil if str.nil?
    s = str.dup
    s.downcase!
    s.gsub!(/'/, '')
    s.gsub!(/[^A-Za-z0-9]+/, ' ')
    s.strip!
    s.gsub!(/\ +/, '-')
    return s
  end  
  
  def transliterate(str)
    Mogrify::transliterate(str)
  end

  
  def transliterate_file_name(str)
    logger.info "tfn gets: #{str}"
    extension = File.extname(str).gsub(/^\.+/, '')
    filename = str.gsub(/\.#{extension}$/, '')
    return "#{transliterate(filename)}.#{transliterate(extension)}"
  end  

end