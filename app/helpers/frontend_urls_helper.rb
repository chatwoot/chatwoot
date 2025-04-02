module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    url_params = query_params.blank? ? '' : "?#{query_params.to_query}"
    host = ENV.fetch('FRONTEND_URL_EXTERNAL', root_url)
    "#{host}app/#{path}#{url_params}"
  end
end
