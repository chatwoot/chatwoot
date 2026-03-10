# frozen_string_literal: true

class Api::V1::Accounts::PaymentPresetsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_preset, only: [:update, :destroy]

  def index
    @presets = Current.account.payment_presets.order(:name)
    render json: @presets
  end

  def create
    @preset = Current.account.payment_presets.create!(permitted_params)
    render json: @preset, status: :created
  end

  def update
    @preset.update!(permitted_params)
    render json: @preset
  end

  def destroy
    @preset.destroy!
    head :ok
  end

  private

  def fetch_preset
    @preset = Current.account.payment_presets.find(params[:id])
  end

  def permitted_params
    params.require(:payment_preset).permit(:name, :amount_cents, :description)
  end
end
