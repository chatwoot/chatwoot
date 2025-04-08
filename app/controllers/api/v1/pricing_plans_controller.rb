class Api::V1::PricingPlansController < ApplicationController
    before_action :set_plan, only: [:show]

      def index
        plans = PricingPlan.all
        render json: plans
      end

      def show
        render json: @plan
      end

      private

      def set_plan
        @plan = PricingPlan.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Plan not found" }, status: :not_found
      end
end
