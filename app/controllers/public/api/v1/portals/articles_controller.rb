class Public::Api::V1::Portals::ArticlesController < ApplicationController
  before_action :set_portal
  before_action :set_article, only: [:show]

  def index
    @articles = @portal.articles
    @articles = @articles.search(list_params) if params[:payload].present?
  end

  def show; end

  private

  def set_article
    @article = @portal.articles.find(params[:id])
  end

  def set_portal
    @portal = ::Portal.find_by!(slug: params[:portal_slug], archived: false)
  end

  def list_params
    params.require(:payload).permit(:query)
  end
end
