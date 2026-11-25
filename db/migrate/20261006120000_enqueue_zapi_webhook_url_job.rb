class EnqueueZapiWebhookUrlJob < ActiveRecord::Migration[7.1]
  # Migrations run before the new web processes take traffic, and a Z-API instance moved to
  # the new URL while an old process still answers would post to a route that process does
  # not have. The wait lets the rollout finish first.
  def up
    Migration::ZapiWebhookUrlJob.set(wait: 10.minutes).perform_later
  end

  def down; end
end
