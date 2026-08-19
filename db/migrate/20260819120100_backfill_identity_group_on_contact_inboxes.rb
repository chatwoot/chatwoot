class BackfillIdentityGroupOnContactInboxes < ActiveRecord::Migration[7.1]
  # One group per existing row, which is the only assignment that guesses nothing. It degrades to
  # the behaviour that predates coexistence, where one source id was one identity by construction,
  # and groups then form as payloads arrive carrying identifiers together. Nothing is grouped that
  # was not observed together.
  def up
    # rubocop:disable Rails/SkipsModelValidations
    ContactInbox.where(identity_group_id: nil).in_batches(of: 1000) do |batch|
      batch.update_all('identity_group_id = gen_random_uuid()')
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    # no-op: rolling back the column drops the values with it
  end
end
