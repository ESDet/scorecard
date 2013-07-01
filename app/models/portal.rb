class Portal

  BASE = 'http://v2.dev.portal.excellentschoolsdetroit.org/api/1.0/'
  
  def listVocabularies
    o = fetch 'taxonomy_vocabulary.json/'
    return o
  end
  
  def showVocabulary(vid)
    o = fetch 'taxonomy_vocabulary/getTree.json/', { vid: vid }
  end
  
  def getRelated(tid)
    o = fetch 'taxonomy_term/selectNodes.json', { tid: tid }
  end
  
  # Possible views: meap_2012, esd_k8_2013, esd_hs_2013
  def getDataset(view, opts={})
    o = fetch "views/#{view}.json/", opts
  end
  
  
  
  
  def url_for(path)
    "#{BASE}#{path}"
  end
  
  def fetch(path, data={})
    url = url_for(path)
    puts "Fetching #{url} with #{data.inspect}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    query = data.blank? ? "" : "?#{data.to_query}"
    headers = {}
    response = http.get(uri.path + query, headers)
    puts response.inspect
    puts response.body
    o = JSON.parse(response.body)
    return o
  end

end