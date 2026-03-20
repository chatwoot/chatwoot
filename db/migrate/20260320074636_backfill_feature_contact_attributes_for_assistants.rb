class BackfillFeatureContactAttributesForAssistants < ActiveRecord::Migration[7.1]
  # Only backfill assistants on accounts with captain_integration_v2 enabled.
  # V1 assistants never had contact attributes, so limit to v2.
  V2_FLAG_MASK = 70_368_744_177_664

  def up
    execute <<~SQL.squish
      UPDATE captain_assistants
      SET config = config || '{"feature_contact_attributes": true}'::jsonb
      WHERE (config ->> 'feature_contact_attributes') IS NULL
        AND account_id IN (
          SELECT id FROM accounts WHERE (feature_flags & #{V2_FLAG_MASK}) = #{V2_FLAG_MASK}
        )
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE captain_assistants
      SET config = config - 'feature_contact_attributes'
      WHERE (config ->> 'feature_contact_attributes') = 'true'
        AND account_id IN (
          SELECT id FROM accounts WHERE (feature_flags & #{V2_FLAG_MASK}) = #{V2_FLAG_MASK}
        )
    SQL
  end
end
