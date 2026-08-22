# Restore/enable the CSV import feature. Agents can import; only administrators
# manage bulk data operations.
class CsvImportPolicy < ApplicationPolicy
  def create?
    @account_user.administrator?
  end
end

CsvImportPolicy.prepend_mod_with('CsvImportPolicy')
