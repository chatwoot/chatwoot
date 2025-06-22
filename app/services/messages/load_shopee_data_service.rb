class Messages::LoadShopeeDataService
  pattr_initialize [:message!]
  # This service loads the Shopee data into the message content attributes.
  # It is used to set the metadata for Shopee card messages.
  # The metadata includes voucher type, usage quantity, current usage, etc.

  def perform
    return unless message.shopee_card?
    return if loaded?

    message.content_attributes[:loaded_data] = card_data
    mark_as_loaded!
    message.save!
  end

  private

  def original_data
    @original_data ||= message.content_attributes.dig('original') || {}
  end

  def channel
    @channel ||= message.conversation.inbox.channel
  end

  def card_data
    if original_data['voucher_id'].present?
      voucher_data
    elsif original_data['order_sn'].present?
      order_data
    elsif item_list?
      { items: items_data }
    else
      {}
    end
  end

  def item_list?
    @item_codes = original_data['item_ids'].to_a.pluck('item_id').compact.presence
    @item_codes ||= original_data['item_ids'].presence
    @item_codes ||= [original_data['item_id'].presence].compact
    @item_codes = @item_codes.map(&:to_s) if @item_codes.is_a?(Array)
    @item_codes.present?
  end

  def loaded?
    message.content_attributes[:shopee_loaded].present?
  end

  def mark_as_loaded!
    message.content_attributes[:shopee_loaded] = true
  end

  def voucher_data
    voucher_id = original_data['voucher_id']
    voucher = channel.vouchers.find_by(voucher_id: voucher_id)
    voucher ||= Shopee::SyncVoucherInfoService.new(channel_id: channel.id, voucher_id: voucher_id).perform
    {
      code: voucher.code,
      name: voucher.name,
      shopeId: channel.shop_id,
      startTime: voucher.start_time,
      endTime: voucher.end_time,
      meta: voucher.meta
    }
  end

  def order_data
    order_number = original_data['order_sn']
    order = channel.orders.find_by(number: order_number)
    order ||= Shopee::SyncOrderInfoService.new(channel_id: channel.id, order_number: order_number).perform
    items = order.order_items.map do |item|
      {
        shopId: channel.shop_id,
        code: item.code,
        itemCode: item.item_code,
        itemSku: item.item_sku,
        itemName: item.item_name,
        price: item.price,
        meta: item.meta
      }
    end
    {
      number: order.number,
      status: order.status,
      cod: order.cod,
      shopeId: channel.shop_id,
      totalAmount: order.total_amount,
      meta: order.meta,
      items: items
    }
  end

  def items_data
    sync_missing_items
    channel.items.where(code: @item_codes).map do |item|
      {
        shopId: channel.shop_id,
        code: item.code,
        sku: item.sku,
        name: item.name,
        status: item.status,
        meta: item.meta
      }
    end
  end

  def sync_missing_items
    missing_item_codes = channel.items.where(code: @item_codes).pluck(:code) - @item_codes
    return if missing_item_codes.empty?

    Shopee::SyncProductInfoJob.new.perform(
      channel_id: channel.id,
      shopee_item_ids: missing_item_codes
    )
  end
end
