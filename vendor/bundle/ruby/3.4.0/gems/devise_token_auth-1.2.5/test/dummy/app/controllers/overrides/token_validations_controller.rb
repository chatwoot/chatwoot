# frozen_string_literal: true

module Overrides
  class TokenValidationsController < DeviseTokenAuth::TokenValidationsController
    OVERRIDE_PROOF = '(^^,)'.freeze

    def validate_token
      # @resource will have been set by set_user_by_token concern
      if @resource
        render json: {
          success: true,
          data: @resource.as_json(except: %i[tokens created_at updated_at]),
          override_proof: OVERRIDE_PROOF
        }
      else
        render json: {
          success: false,
          errors: ['Invalid login credentials']
        }, status: 401
      end
    end
  end
end
