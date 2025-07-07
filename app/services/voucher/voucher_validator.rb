class Voucher::VoucherValidator
  def initialize(code:, account:, subscription_plan_id:)
    @code = code
    @account = account
    @plan_id = subscription_plan_id
  end

  def validate
    voucher = Voucher.find_by(code: @code)
    return { valid: false, error: 'Voucher tidak ditemukan' } unless voucher

    unless voucher.subscription_plans.exists?(id: @plan_id)
      return { valid: false, error: 'Voucher tidak berlaku untuk paket ini' }
    end

    unless voucher.usable_by?(@account)
      return { valid: false, error: 'Voucher tidak bisa digunakan lagi' }
    end

    { valid: true, voucher: voucher }
  end
end