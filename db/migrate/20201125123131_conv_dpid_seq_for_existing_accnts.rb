class ConvDpidSeqForExistingAccnts < ActiveRecord::Migration[6.0]
  def up
    ::Account.find_in_batches do |accounts_batch|
      Rails.logger.info "migrated till #{accounts_batch.first.id}\n"
      accounts_batch.each do |account|
        display_id = Conversation.where(account_id: account.id).maximum('display_id')
        display_id ||= 0 # for accounts with out conversations
        ActiveRecord::Base.connection.exec_query("create sequence IF NOT EXISTS conv_dpid_seq_#{account.id} START #{display_id + 1}")
      end
    end
  end

  def down
    ::Account.find_in_batches do |accounts_batch|
      Rails.logger.info "migrated till #{accounts_batch.first.id}\n"
      accounts_batch.each do |account|
        ActiveRecord::Base.connection.exec_query("drop sequence IF EXISTS conv_dpid_seq_#{account.id}")
      end
    end
  end
end
