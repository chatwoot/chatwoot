class BackfillPositionOnCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  POSITION_STEP = 10
  ACCOUNT_BATCH_SIZE = 500
  UPDATE_BATCH_SIZE = 1000

  def up
    Account.in_batches(of: ACCOUNT_BATCH_SIZE) do |accounts|
      positions_for(accounts.pluck(:id)).each_slice(UPDATE_BATCH_SIZE) do |positions|
        update_positions(positions)
      end
    end
  end

  def down; end

  private

  def positions_for(account_ids)
    definitions = CustomAttributeDefinition.where(account_id: account_ids).order(:created_at, :id).pluck(:id, :account_id, :attribute_model)
    groups = definitions.group_by { |_id, account_id, attribute_model| [account_id, attribute_model] }

    groups.values.flat_map do |group|
      group.each_with_index.map do |(id, _account_id, _attribute_model), index|
        [id, (index + 1) * POSITION_STEP]
      end
    end
  end

  def update_positions(positions)
    position_by_id = Arel::Nodes::Case.new(CustomAttributeDefinition.arel_table[:id])
    positions.each do |id, position|
      position_by_id.when(id).then(position)
    end

    # rubocop:disable Rails/SkipsModelValidations
    CustomAttributeDefinition.where(id: positions.map(&:first)).update_all(position: position_by_id)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
