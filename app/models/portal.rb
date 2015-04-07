class Portal
  BASE = 'https://portal.excellentschoolsdetroit.org/api/1.0/'

  def list_vocabularies
    fetch 'taxonomy_vocabulary.json/'
  end

  def show_vocabulary(vid)
    fetch 'taxonomy_vocabulary/getTree.json/', { vid: vid, load_entities: 1 }, :post
  end

  def get_related(tid)
    result = fetch 'taxonomy_term/selectNodes.json', { tid: tid }, :post
    result.first
  end

  # Possible views: meap_2012*, esd_k8_2014, esd_hs_2014, act_2014...
  # opts = { :limit => x, :offset => y }
  def get_dataset(view, bcode=nil, opts={})
    data = bcode.nil? ? {} : { 'filters[bcode]' => bcode }
    data.merge!(opts)
    fetch "views/#{view}.json/", data
  end

  def url_for(path)
    "#{BASE}#{path}"
  end

  def fetch(path, data={}, method=:get)
    url = url_for(path)
    #puts "Fetching #{url} with #{data.inspect}"
    query = data.blank? ? "" : "?#{data.to_query}"
    if method == :get
      puts "Getting: #{url + query}"
      response = HTTParty.get(url + query)
    elsif method == :post
      headers = { 'Content-Type' => 'application/json' }
      response = HTTParty.post(url, { :body => data.to_json, :headers => headers })
      #response, data = http.post(uri.path, data.to_json, headers)
    end
    #puts response.inspect
    #puts response.body
    JSON.parse(response.body)
  end
end
