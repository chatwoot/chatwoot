# Verifies that two URLs are equal, ignoring the order of the query string parameters
RSpec::Matchers.define :match_url do |url|
  match do |original_url|
    base, query_string = url.split("?")
    original_base, original_query_string = original_url.split("?")
    query_hash = query_to_params(query_string)
    original_query_hash = query_to_params(original_query_string)

    # the base URLs need to match
    expect(base).to eq(original_base)
    
    # the number of parameters should match (avoid one being a subset of the other)
    expect(query_hash.values.length).to eq(original_query_hash.values.length)
    
    # and ensure all the keys and values match
    query_hash.each_pair do |key, value|
      expect(original_query_hash[key]).to eq(value)
    end
  end
  
  def query_to_params(query_string)
    query_string.split("&").inject({}) do |hash, segment|
      k, v = segment.split("=")
      hash[k] = v
      hash
    end
  end
end