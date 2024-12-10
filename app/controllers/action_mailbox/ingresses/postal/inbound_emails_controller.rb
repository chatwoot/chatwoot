# frozen_string_literal: true

class ActionMailbox::Ingresses::Postal::InboundEmailsController < ActionMailbox::BaseController
  before_action :authenticate_by_password

  def create
    ActionMailbox::InboundEmails.create_and_extract_message_id! Base64.decode64(params.require('message'))
  rescue ActionController::ParameterMissing => e
    logger.error <<~MESSAGE
      #{e.message}
    MESSAGE
    head :unprocessable_entity
  end
end
