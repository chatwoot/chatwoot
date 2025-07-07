class Api::V1::VouchersController < ApplicationController
  def validate
    account = Account.find(params[:account_id])
    plan_id = params[:subscription_plan_id]
    code = params[:voucher_code]

    result =  ::Voucher::VoucherValidator.new(code: code, account: account, subscription_plan_id: plan_id).validate

    if result[:valid]
      render json: {
        success: true,
        discount_type: result[:voucher].discount_type,
        discount_value: result[:voucher].discount_value
      }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end
end