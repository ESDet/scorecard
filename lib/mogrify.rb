module Mogrify

  def transliterate(str)
    # Escape str by transliterating to UTF-8 with Iconv
    #s = Iconv.iconv('ascii//ignore//translit', 'utf-8', str).to_s
    s = str.clone
  
    s.downcase!
    s.gsub!(/'/, '')
    s.gsub!(/[^A-Za-z0-9]+/, ' ')
    s.strip!
    s.gsub!(/\ +/, '-')
  
    return s
  end  
  
  private
  
  def transliterate_file_name(str)
    logger.info "tfn gets: #{str}"
    extension = File.extname(str).gsub(/^\.+/, '')
    filename = str.gsub(/\.#{extension}$/, '')
    return "#{transliterate(filename)}.#{transliterate(extension)}"
  end  

end