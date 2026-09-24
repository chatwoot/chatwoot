module ContactCompanyAssociation
  extend ActiveSupport::Concern

  included do
    belongs_to :company, optional: true, counter_cache: true

    before_save :sync_company_name_from_company, if: :will_save_change_to_company_id?
    after_commit :associate_company_from_email, on: [:create, :update], if: :should_associate_company?
    after_update_commit :record_company_activity, if: :saved_change_to_last_activity_at?

    scope :order_on_company_name, lambda { |direction|
      order(
        Arel::Nodes::SqlLiteral.new(
          sanitize_sql_for_order(
            "\"contacts\".\"additional_attributes\"->>'company_name' #{direction}
            NULLS LAST"
          )
        )
      )
    }
  end

  private

  def should_associate_company?
    email.present? &&
      company_id.nil? &&
      saved_change_to_email? &&
      saved_change_to_email.first.nil? &&
      account.feature_enabled?('companies')
  end

  def associate_company_from_email
    Contacts::CompanyAssociationService.new.associate_company_from_email(self)
  rescue StandardError => e
    Rails.logger.error("Failed to associate company for contact #{id}: #{e.message}")
  end

  def record_company_activity
    company&.record_activity_at!(last_activity_at) if last_activity_at.present?
  end

  def sync_company_name_from_company
    self.additional_attributes ||= {}

    if company_id.present?
      additional_attributes['company_name'] = company&.name
    else
      additional_attributes.delete('company_name')
    end
  end
end
