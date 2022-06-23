class RemoveSpecialCharactersFromInboxName < ActiveRecord::Migration[6.1]
  def change
    remove_special_characters_from_inbox_name
  end

  private

  def remove_special_characters_from_inbox_name
    # ::Inbox.find_in_batches do |inbox_batch|
    #   inbox_batch.map do |inbox|
    #     inbox.name.gsub(/[^\w\s_]/, '')
    #   end
    # end
  end
end
