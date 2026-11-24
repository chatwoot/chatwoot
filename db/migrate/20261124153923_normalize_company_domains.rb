class NormalizeCompanyDomains < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    company_model = Class.new(ActiveRecord::Base) { self.table_name = 'companies' }

    # In ID order, the first company can claim an unused lowercase domain.
    company_model.where('domain <> LOWER(domain)').find_each do |company|
      company.with_lock do
        company.domain = company.domain&.downcase
        company.save!(touch: false)
      end
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique
      # The row was deleted or the account already has the lowercase domain.
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The original company domain casing is no longer available'
  end
end
