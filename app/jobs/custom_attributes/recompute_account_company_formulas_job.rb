class CustomAttributes::RecomputeAccountCompanyFormulasJob < ApplicationJob
  queue_as :low

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return if account.blank?
    return unless account.custom_attribute_definitions.company_attribute.where.not(formula: nil).exists?

    Company.where(account_id: account_id).find_each(batch_size: 100) do |company|
      CustomAttributes::RecomputeCompanyFormulasService.new(company: company).perform
    rescue StandardError => e
      Rails.logger.warn(
        "[RecomputeAccountCompanyFormulasJob] company=#{company.id} error=#{e.class}: #{e.message}"
      )
    end
  end
end
