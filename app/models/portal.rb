class Portal
  include HTTParty
  default_timeout 30

  BASE = 'https://portal.excellentschoolsdetroit.org/api/1.0/'

  def list_vocabularies
    fetch 'taxonomy_vocabulary.json/'
  end

  def show_vocabulary(vid)
    fetch 'taxonomy_vocabulary/getTree.json/', { vid: vid, load_entities: 1, flatten_fields: 1 }, :post
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
    if view =~ /ecs/
      fetch "#{view}.json/", data
    else
      fetch "views/#{view}.json/", data
    end
  end

  def url_for(path)
    "#{BASE}#{path}"
  end

  def fetch(path, data={}, method=:get)
    url = url_for(path)
    query = data.blank? ? "" : "?#{data.to_query}"
    if method == :get
      puts "Getting: #{url + query}"
      response = Portal.get(url + query, verify: false)
    elsif method == :post
      headers = { 'Content-Type' => 'application/json' }
      response = Portal.post(url, { :body => data.to_json, :headers => headers }, verify: false)
      #response, data = http.post(uri.path, data.to_json, headers)
    end
    JSON.parse(response.body) if response.body != ""
  end
end
