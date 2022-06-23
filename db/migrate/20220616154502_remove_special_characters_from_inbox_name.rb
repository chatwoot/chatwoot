class RemoveSpecialCharactersFromInboxName < ActiveRecord::Migration[6.1]
  def change
    remove_special_characters_from_inbox_name
  end

  private

  def remove_special_characters_from_inbox_name
    ::Inbox.find_in_batches do |inbox_batch|
      Rails.logger.info "Migrated till #{inbox_batch.first.id}\n"
      inbox_batch.each do |inbox|
        inbox.name = inbox.name.gsub(/[^\w\s_]/, '')
        inbox.save!
      end
    end
  end
end
