module Custom::Api::V1::Accounts::CustomAttributeDefinitionsController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_custom_attribute_definitions_quota, only: [:create]
  end

  private

  def check_custom_attribute_definitions_quota
    check_quota(:custom_attribute_definitions)
  end
end
