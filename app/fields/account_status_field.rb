require 'administrate/field/select'

class AccountStatusField < Administrate::Field::Select
  def to_partial_path
    return '/fields/account_status_field/form' if page == :form

    "/fields/select/#{page}"
  end

  def suspension_category_options
    Account::SUSPENSION_CATEGORIES.map do |category|
      [I18n.t("super_admin.account_suspension.categories.#{category}"), category]
    end
  end

  def latest_suspension
    resource.suspension_history.last || {}
  end

  def original_status
    resource.status_in_database || resource.status
  end
end
