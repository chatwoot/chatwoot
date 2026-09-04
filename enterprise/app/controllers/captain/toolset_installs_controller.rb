class Captain::ToolsetInstallsController < ApplicationController
  def show
    query = { source: params.require(:source) }.to_query
    redirect_to "/app/captain/toolsets/install?#{query}"
  end
end
