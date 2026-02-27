class SwaggerController < ApplicationController
  skip_before_action :set_current_user

  def respond
    file_path = Rails.root.join('swagger', derived_path)
    send_data file_path.read, type: content_type_for(derived_path), disposition: :inline
  end

  private

  def derived_path
    params[:path] ||= 'index.html'
    path = Rack::Utils.clean_path_info(params[:path])
    path << ".#{Rack::Utils.clean_path_info(params[:format])}" unless path.ends_with?(params[:format].to_s)
    path
  end

  def content_type_for(path)
    case File.extname(path)
    when '.json' then 'application/json'
    when '.yaml', '.yml' then 'text/yaml'
    when '.html' then 'text/html'
    else 'application/octet-stream'
    end
  end
end
