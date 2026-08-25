require 'administrate/field/base'

class SuspensionHistoryField < Administrate::Field::Base
  def events
    data.reverse
  end

  def category_label(event)
    I18n.t("super_admin.account_suspension.categories.#{event.fetch('category')}")
  end

  def suspended_at(event)
    I18n.l(Time.zone.parse(event.fetch('suspended_at')), format: :long)
  end
end
