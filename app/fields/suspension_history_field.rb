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

  def suspended_by(event)
    @user_names ||= User.where(id: data.pluck('suspended_by').compact).pluck(:id, :name).to_h
    @user_names[event['suspended_by']] || I18n.t('super_admin.account_suspension.history.unknown_user')
  end
end
