class BackfillPositionOnCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  POSITION_STEP = 10

  def up
    account_ids = CustomAttributeDefinition.where(position: nil).distinct.pluck(:account_id)

    account_ids.each do |account_id|
      backfill_account(account_id)
    end
  end

  def down; end

  private

  def backfill_account(account_id)
    definitions = CustomAttributeDefinition.where(account_id: account_id).order(:created_at, :id).pluck(:id, :attribute_model)

    CustomAttributeDefinition.transaction do
      definitions.group_by(&:last).each_value do |group|
        group.each_with_index do |(id, _attribute_model), index|
          # rubocop:disable Rails/SkipsModelValidations
          CustomAttributeDefinition.where(id: id).update_all(position: (index + 1) * POSITION_STEP)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end
    end
  end
end
