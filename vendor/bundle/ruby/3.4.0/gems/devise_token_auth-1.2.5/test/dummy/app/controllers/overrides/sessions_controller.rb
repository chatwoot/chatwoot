# frozen_string_literal: true

module Overrides
  class SessionsController < DeviseTokenAuth::SessionsController
    OVERRIDE_PROOF = '(^^,)'.freeze

    def create
      @resource = resource_class.dta_find_by(email: resource_params[:email])

      if @resource && valid_params?(:email, resource_params[:email]) && @resource.valid_password?(resource_params[:password]) && @resource.confirmed?
        @token = @resource.create_token
        @resource.save

        render json: {
          data: @resource.as_json(except: %i[tokens created_at updated_at]),
          override_proof: OVERRIDE_PROOF
        }

      elsif @resource && (not @resource.confirmed?)
        render json: {
          success: false,
          errors: [
            "A confirmation email was sent to your account at #{@resource.email}. "\
            'You must follow the instructions in the email before your account '\
            'can be activated'
          ]
        }, status: 401

      else
        render json: {
          errors: ['Invalid login credentials. Please try again.']
        }, status: 401
      end
    end
  end
end
