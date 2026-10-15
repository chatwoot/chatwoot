class Whatsapp::CatalogMessagePayloadBuilder
  class Error < StandardError; end

  ITEM_LIMITS = {
    'carousel' => 2..10,
    'product' => 1..1,
    'product_list' => 1..30
  }.freeze
  BODY_MAX_LENGTH = 1024
  FOOTER_MAX_LENGTH = 60
  HEADER_MAX_LENGTH = 60
  SECTION_TITLE_MAX_LENGTH = 24

  pattr_initialize [:body!, :catalog!]

  def perform
    validate!
    send("#{kind}_payload")
  end

  private

  def kind
    catalog['kind']
  end

  def items
    catalog['items'].to_a
  end

  def validate!
    raise Error, I18n.t('errors.whatsapp.catalog.unknown_kind', kind: kind) unless ITEM_LIMITS.key?(kind)

    validate_products!
    validate_texts!
  end

  def validate_products!
    limit = ITEM_LIMITS[kind]
    raise Error, I18n.t('errors.whatsapp.catalog.catalog_id_required') if catalog['catalog_id'].blank?
    raise Error, I18n.t('errors.whatsapp.catalog.items_out_of_range', kind: kind, min: limit.min, max: limit.max) unless limit.cover?(items.size)
    raise Error, I18n.t('errors.whatsapp.catalog.retailer_id_required') if items.any? { |item| item['retailer_id'].blank? }
  end

  def validate_texts!
    raise Error, I18n.t('errors.whatsapp.catalog.body_required', kind: kind) if kind != 'product' && body.blank?
    raise Error, I18n.t('errors.whatsapp.catalog.header_required') if kind == 'product_list' && catalog['header'].blank?

    validate_length!('body', body, BODY_MAX_LENGTH)
    validate_length!('footer', catalog['footer'], FOOTER_MAX_LENGTH)
    validate_list_lengths! if kind == 'product_list'
  end

  def validate_list_lengths!
    validate_length!('header', catalog['header'], HEADER_MAX_LENGTH)
    items.each { |item| validate_length!('section', item['section'], SECTION_TITLE_MAX_LENGTH) }
  end

  def validate_length!(field, text, max)
    raise Error, I18n.t('errors.whatsapp.catalog.text_too_long', field: field, max: max) if text.to_s.length > max
  end

  def carousel_payload
    {
      type: 'carousel',
      body: { text: body },
      action: {
        cards: items.each_with_index.map do |item, index|
          {
            card_index: index,
            type: 'product',
            action: { product_retailer_id: item['retailer_id'], catalog_id: catalog['catalog_id'] }
          }
        end
      }
    }
  end

  def product_payload
    payload = { type: 'product' }
    payload[:body] = { text: body } if body.present?
    payload[:footer] = { text: catalog['footer'] } if catalog['footer'].present?
    payload.merge(action: { catalog_id: catalog['catalog_id'], product_retailer_id: items.first['retailer_id'] })
  end

  def product_list_payload
    payload = { type: 'product_list', header: { type: 'text', text: catalog['header'] }, body: { text: body } }
    payload[:footer] = { text: catalog['footer'] } if catalog['footer'].present?
    payload.merge(action: { catalog_id: catalog['catalog_id'], sections: sections })
  end

  def sections
    items.group_by { |item| item['section'] }.map do |title, section_items|
      { title: title, product_items: section_items.map { |item| { product_retailer_id: item['retailer_id'] } } }
    end
  end
end
