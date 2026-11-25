# The text a catalog product or order is stored as: what the conversation list, search and
# notifications show, and what an agent reads where the card is not drawn. Written in the
# caller's locale, which the writer sets to the account's, from the amounts in thousandths
# the connector sends. A price WhatsApp did not send is left out, never written as zero.
module Whatsapp::Session::CatalogText
  SYMBOLS = { 'BRL' => 'R$', 'USD' => 'US$', 'EUR' => '€', 'GBP' => '£' }.freeze
  # ISO 4217 minor units that are not two, so the stored text says the same amount the
  # card does (the dashboard formats with Intl, which knows them).
  NO_DECIMALS = %w[BIF CLP DJF GNF ISK JPY KMF KRW PYG RWF UGX VND VUV XAF XOF XPF].freeze
  THREE_DECIMALS = %w[BHD IQD JOD KWD LYD OMR TND].freeze
  DECIMALS = NO_DECIMALS.index_with(0).merge(THREE_DECIMALS.index_with(3)).freeze

  class << self
    def product(product)
      text = [product.title, price(product.current_price_1000, product.currency), product.description].compact_blank.join("\n\n")
      text.presence || t('product_unreadable')
    end

    def order(order, note: nil)
      summary = [t('order_title', id: order.id), totals(order)].compact_blank.join("\n")
      [summary, note, items(order)].compact_blank.join("\n\n")
    end

    def price(amount_1000, currency)
      return if amount_1000.nil? || currency.blank?

      number = ActiveSupport::NumberHelper.number_to_rounded(
        BigDecimal(amount_1000) / 1000, precision: DECIMALS.fetch(currency, 2), separator: t('separator'), delimiter: t('delimiter')
      )
      t('price', unit: SYMBOLS.fetch(currency, currency), number: number)
    end

    private

    def totals(order)
      total = price(order.total_1000, order.currency)
      [
        (t('item_count', count: order.units) unless order.units.nil?),
        (t('estimated_total', total: total) if total)
      ].compact.join(' · ')
    end

    def items(order)
      Array(order.items).map do |item|
        name = item.variant.present? ? "#{item.name} (#{item.variant})" : item.name
        line = "• #{name} × #{item.quantity}"
        amount = price(item.price_1000, item.currency.presence || order.currency)
        amount ? "#{line} · #{amount}" : line
      end.join("\n")
    end

    def t(key, **) = I18n.t("whatsapp_catalog.#{key}", **)
  end
end
