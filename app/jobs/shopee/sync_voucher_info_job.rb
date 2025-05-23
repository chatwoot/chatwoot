class Shopee::SyncVoucherInfoJob < ApplicationJob
  queue_as :medium

  METADATA_KEYS = %w[
    voucher_type
    usage_quantity
    current_usage
    voucher_purpose
    percentage
    max_price
    min_basket_price
    discount_amount
    target_voucher
    usecase
  ].freeze

  def perform(channel_id:, voucher_id:)
    @channel = Channel::Shopee.find(channel_id)
    @voucher_id = voucher_id

    update_or_create_voucher
  end

  private
  attr_reader :channel
  attr_reader :voucher_id

  def shopee_voucher
    @shopee_voucher ||= Integrations::Shopee::Voucher.new(
      shop_id: channel.shop_id,
      access_token: channel.access_token,
    ).detail(voucher_id)
  end

  def update_or_create_voucher
    Shopee::Voucher.find_or_initialize_by(
      shop_id: channel.shop_id,
      voucher_id: shopee_voucher['voucher_id'],
    ).update!(
      code: shopee_voucher['voucher_code'],
      name: shopee_voucher['voucher_name'],
      start_time: Time.at(shopee_voucher['start_time']),
      end_time: Time.at(shopee_voucher['end_time']),
      meta: shopee_voucher.slice(*METADATA_KEYS),
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to process voucher: #{shopee_voucher['voucher_id']}, Error: #{e.message}")
  end

end
