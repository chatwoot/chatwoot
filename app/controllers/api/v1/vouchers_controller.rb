class Api::V1::VouchersController < ApplicationController
  def validate
    account = Account.find(params[:account_id]) unless params[:account_id].nil?
    plan_id = params[:subscription_plan_id]
    code = params[:voucher_code]
    billing_cycle = params[:billing_cycle]

    result = ::Voucher::VoucherValidator.new(
      code: code, 
      account: account, 
      subscription_plan_id: plan_id,
      billing_cycle: billing_cycle
    ).validate

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

  def preview
    account = Account.find(params[:account_id]) unless params[:account_id].nil?
    plan_id = params[:subscription_plan_id]
    code = params[:voucher_code]
    price = params[:price]
    billing_cycle = params[:billing_cycle]

    result = Voucher::VoucherPreview.new().preview(code, account, plan_id, price, billing_cycle: billing_cycle)
    if result[:voucher][:valid]
      render json: result
    else
      render json: { success: false, error: result[:voucher][:error] }, status: :unprocessable_entity
    end
  end
end