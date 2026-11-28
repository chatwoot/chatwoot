class NormalizeCompanyDomains < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    domain = Company.arel_table[:domain]
    # In ID order, the first company can claim an unused lowercase domain.
    Company.where(domain.not_eq(domain.lower)).find_each do |company|
      company.with_lock do
        # Change only the domain casing without validating unrelated legacy fields.
        company.update_column(:domain, company.domain&.downcase) # rubocop:disable Rails/SkipsModelValidations
      end
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique
      # The row was deleted or the account already has the lowercase domain.
    end
  end

  def down
    # Keep normalized domains when rolling back the application.
  end
end
