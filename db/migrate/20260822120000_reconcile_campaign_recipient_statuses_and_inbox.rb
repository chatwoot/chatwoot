# PaluHub OSS used a different status enum than upstream Enterprise analytics.
# Remap legacy integers and backfill inbox_id so WhatsApp status webhooks can match recipients.
class ReconcileCampaignRecipientStatusesAndInbox < ActiveRecord::Migration[7.1]
  def up
    backfill_inbox_ids
    remap_legacy_statuses
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def backfill_inbox_ids
    execute <<~SQL.squish
      UPDATE campaign_recipients AS cr
      SET inbox_id = c.inbox_id
      FROM campaigns AS c
      WHERE cr.campaign_id = c.id
        AND cr.inbox_id IS NULL
    SQL
  end

  def remap_legacy_statuses
    execute <<~SQL.squish
      UPDATE campaign_recipients
      SET status = CASE status
        WHEN 5 THEN 1
        WHEN 1 THEN CASE WHEN source_id IS NOT NULL THEN 2 ELSE 1 END
        WHEN 2 THEN CASE WHEN delivered_at IS NOT NULL THEN 3 ELSE 2 END
        WHEN 3 THEN CASE WHEN read_at IS NOT NULL THEN 4 ELSE 3 END
        WHEN 4 THEN CASE
          WHEN failed_at IS NOT NULL OR (error_message IS NOT NULL AND read_at IS NULL) THEN 5
          ELSE 4
        END
        ELSE status
      END
      WHERE status IN (1, 2, 3, 4, 5)
        AND (
          status = 5
          OR (status = 1 AND source_id IS NOT NULL)
          OR (status = 2 AND delivered_at IS NOT NULL)
          OR (status = 3 AND read_at IS NOT NULL)
          OR (status = 4 AND (failed_at IS NOT NULL OR (error_message IS NOT NULL AND read_at IS NULL)))
        )
    SQL
  end
end
