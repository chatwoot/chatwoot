class DocsController < ApplicationController
  # Serves the combined OpenAPI/Swagger JSON for WSC
  def openapi
    spec_path = Rails.root.join('swagger', 'swagger.json')
    if File.exist?(spec_path)
      send_file spec_path, type: 'application/json; charset=utf-8', disposition: 'inline'
    else
      render json: { error: 'Spec not found' }, status: :not_found
    end
  end
end

