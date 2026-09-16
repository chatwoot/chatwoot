# frozen_string_literal: true

other_plural_rule = ->(_count) { :other }

Rails.application.config.after_initialize do
  I18n.backend.store_translations(:zh_CN, i18n: { plural: { rule: other_plural_rule } })
  I18n.backend.store_translations(:zh_TW, i18n: { plural: { rule: other_plural_rule } })
end
