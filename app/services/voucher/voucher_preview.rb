class Voucher::VoucherPreview
  def preview(code, account, subscription_plan_id, price, billing_cycle: nil)
    result = Voucher::VoucherValidator.new(
      code: code, 
      account: account, 
      subscription_plan_id: subscription_plan_id,
      billing_cycle: billing_cycle
    ).validate

    unless result[:valid]
      return {
        voucher: result,
      }
    end
    
    voucher = result[:voucher]
    new_price = if voucher.idr?
      [price - voucher.discount_value, 0].max
    else
      (price * (100 - voucher.discount_value) / 100.0).to_i
    end

    { new_price: new_price, voucher: result }
  end
end