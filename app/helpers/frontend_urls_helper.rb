module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
    host = ENV.fetch('FRONTEND_URL', root_url)
    host = "#{host}/" unless host.end_with?('/')
    "#{host}app/#{path}#{url_params}"
  end
end
