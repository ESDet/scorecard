class Portal

  BASE = 'http://portal.excellentschoolsdetroit.org/api/1.0/'
  
  def list_vocabularies
    o = fetch 'taxonomy_vocabulary.json/'
    return o
  end
  
  def show_vocabulary(vid)
    o = fetch 'taxonomy_vocabulary/getTree.json/', { vid: vid, load_entities: 1 }, :post
  end
  
  def get_related(tid)
    result = fetch 'taxonomy_term/selectNodes.json', { tid: tid }, :post
    result.first
  end
  
  # Possible views: meap_2012, esd_k8_2013, esd_hs_2013
  # opts = { :limit => x, :offset => y }
  def get_dataset(view, bcode=nil, opts={})
    data = bcode.nil? ? {} : { 'filters[bcode]' => bcode } 
    data.merge!(opts)
    o = fetch "views/#{view}.json/", data
  end
  
  
  
  
  def url_for(path)
    "#{BASE}#{path}"
  end
  
  def fetch(path, data={}, method=:get)
    url = url_for(path)
    #puts "Fetching #{url} with #{data.inspect}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    query = data.blank? ? "" : "?#{data.to_query}"
    if method == :get
      headers = {}
      response = http.get(uri.path + query, headers)
    elsif method == :post
      headers = { 'Content-Type' => 'application/json' }
      response, data = http.post(uri.path, data.to_json, headers)
    end
    #puts response.inspect
    #puts response.body
    o = JSON.parse(response.body)
    return o
  end

end