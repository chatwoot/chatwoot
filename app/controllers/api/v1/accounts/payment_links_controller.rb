# frozen_string_literal: true

class Api::V1::Accounts::PaymentLinksController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @payment_links = Current.account.payment_links
    @payment_links = @payment_links.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    @payment_links = @payment_links.order(created_at: :desc).limit(20)
    render json: @payment_links
  end

  def create
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])

    payment_link = Integrations::Infinitepay::CreateLinkService.new(
      account: Current.account,
      conversation: conversation,
      user: Current.user,
      amount_cents: params[:amount_cents].to_i,
      description: params[:description],
      payment_method: params[:payment_method],
      installments: params[:installments]&.to_i
    ).perform

    render json: payment_link, status: :created
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("PaymentLink creation failed: #{e.class} - #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
