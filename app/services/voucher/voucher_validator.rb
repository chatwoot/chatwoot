class Voucher::VoucherValidator
  def initialize(code:, account:, subscription_plan_id:, billing_cycle: nil)
    @code = code
    @account = account
    @plan_id = subscription_plan_id
    @billing_cycle = billing_cycle
  end

  def validate
    voucher = Voucher.find_by(code: @code)
    return { valid: false, error: 'Voucher tidak ditemukan' } unless voucher

    unless voucher.subscription_plans.exists?(id: @plan_id)
      return { valid: false, error: 'Voucher tidak berlaku untuk paket ini' }
    end

    # Validasi billing cycle
    if @billing_cycle.present?
      unless voucher.applicable_to_plan_and_cycle?(@plan_id, @billing_cycle)
        return { valid: false, error: 'Voucher tidak berlaku untuk siklus pembayaran ini' }
      end
    end

    # Gunakan method usable_by? dengan billing_cycle
    unless voucher.usable_by?(@account, @plan_id, @billing_cycle)
      return { valid: false, error: 'Voucher tidak bisa digunakan lagi' }
    end

    { valid: true, voucher: voucher }
  end
end