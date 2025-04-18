class SwaggerController < ApplicationController
  def respond
    # Allow Swagger in all environments
    render inline: Rails.root.join('swagger', derived_path).read
  end

  private

  def derived_path
    params[:path] ||= 'index.html'
    path = Rack::Utils.clean_path_info(params[:path])
    path << ".#{Rack::Utils.clean_path_info(params[:format])}" unless path.ends_with?(params[:format].to_s)
    path
  end
end
