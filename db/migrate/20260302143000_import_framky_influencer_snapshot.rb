require 'json'

class ImportFramkyInfluencerSnapshot < ActiveRecord::Migration[7.0]
  def up
    return say('Skipping Framky influencer snapshot import: snapshot file is missing', true) unless snapshot_path.exist?

    account = resolve_account
    return say('Skipping Framky influencer snapshot import: target account was not resolved', true) unless account

    imported_count = Influencers::SnapshotImporter.new(account: account, snapshot_path: snapshot_path).perform

    say "Imported #{imported_count} influencer profiles into account #{account.id} (#{account.name})", true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def resolve_account
    return Account.find_by(id: ENV['INFLUENCER_IMPORT_ACCOUNT_ID']) if ENV['INFLUENCER_IMPORT_ACCOUNT_ID'].present?

    accounts = Account.where(name: snapshot.fetch('account', {}).fetch('name'))
    return accounts.first if accounts.one?

    nil
  end

  def snapshot
    @snapshot ||= JSON.parse(File.read(snapshot_path))
  end

  def snapshot_path
    Rails.root.join('db/influencer_snapshots/framky.json')
  end
end
