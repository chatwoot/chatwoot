class SwaggerController < ApplicationController
  def respond
    # Allow Swagger in all environments
    if params[:path].present?
      target_path = params[:path]
    else
      target_path = 'index.html'
    end
    
    Rails.logger.info("Swagger requested path: #{target_path.inspect}")
    
    file_path = Rails.root.join('swagger', target_path)
    Rails.logger.info("Full file path: #{file_path.inspect}")
    Rails.logger.info("File exists: #{File.exist?(file_path)}")
    
    if File.exist?(file_path)
      if target_path.end_with?('.json')
        render json: File.read(file_path)
      else
        render inline: File.read(file_path)
      end
    else
      render status: 404, json: { error: 'File not found', path: target_path }
    end
  end

  private

  def derived_path
    params[:path] ||= 'index.html'
    path = Rack::Utils.clean_path_info(params[:path])
    path << ".#{Rack::Utils.clean_path_info(params[:format])}" if params[:format].present? && !path.ends_with?(params[:format].to_s)
    path
  end
end
