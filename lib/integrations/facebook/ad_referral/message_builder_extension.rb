# frozen_string_literal: true

module Integrations::Facebook::AdReferral
  module MessageBuilderExtension
    private

    def message_params
      params = super
      referral = response.referral
      params[:content_attributes][:referral] = referral if !@outgoing_echo && referral.present?
      params
    end
  end
end
