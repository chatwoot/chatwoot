module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
    # Ensure no double slashes by removing trailing slash from root_url
    base_url = root_url.chomp('/')
    "#{base_url}/app/#{path}#{url_params}"
  end
end
