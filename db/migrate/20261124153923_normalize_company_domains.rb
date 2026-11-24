class NormalizeCompanyDomains < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    company_model = Class.new(ActiveRecord::Base) do
      self.table_name = 'companies'
      self.record_timestamps = false
    end
    domain = company_model.arel_table[:domain]
    company_model.where(domain.not_eq(domain.lower)).find_each do |company|
      normalize_domain(company, company_model)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The original company domain casing is no longer available'
  end

  private

  def normalize_domain(company, company_model)
    company.with_lock do
      domain = company.domain&.downcase
      next if domain == company.domain
      next if company_model.exists?(account_id: company.account_id, domain: domain)

      company.update!(domain: domain)
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique
    # The company was deleted or another write claimed the lowercase domain.
  end
end
