module FrontendUrlsHelper
  def frontend_url(path, **query_params)
    "#{root_url}app/#{path}?#{query_params.to_query}"
  end
end
