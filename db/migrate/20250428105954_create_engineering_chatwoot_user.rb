class CreateEngineeringChatwootUser < ActiveRecord::Migration[7.0]
  def change
    Migration::GenerateDigitaltolkTokenJob.perform_later
  end
end
