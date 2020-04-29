class Api::V1::Account::Integrations::AppsController < ApplicationController
  before_action :fetch_apps, only: [:index]
  before_action :fetch_app, only: [:show]

  def index; end

  def show; end

  private

  def fetch_apps
    @apps = Integrations::App.all
  end

  def fetch_app
  end
end
