class Integrations::Shopee::Voucher < Integrations::Shopee::Base
  MAX_PAGE_SIZE = 100

  def sendable
    ongoing_vouchers + upcoming_vouchers
  end

  private

  def ongoing_vouchers
    auth_client
      .query({ page_size: MAX_PAGE_SIZE, status: :ongoing })
      .get('/api/v2/voucher/get_voucher_list')
      .dig('response', 'voucher_list')
  end

  def upcoming_vouchers
    auth_client
      .query({ page_size: MAX_PAGE_SIZE, status: :upcoming })
      .get('/api/v2/voucher/get_voucher_list')
      .dig('response', 'voucher_list')
  end
end
