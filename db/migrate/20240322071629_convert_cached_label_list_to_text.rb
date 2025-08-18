class ConvertCachedLabelListToText < ActiveRecord::Migration[7.0]
  def up
    change_column :conversations, :cached_label_list, :text
  end

  def down
    # This might cause data loss if the text is longer than 255 characters
    # lets start by truncating the data to 255 characters
    Conversation.where('LENGTH(cached_label_list) > 255').find_in_batches do |conversation_batch|
      Conversation.transaction do
        conversation_batch.each do |conversation|
          conversation.update!(cached_label_list: truncate_list(conversation.cached_label_list))
        end
      end
    end

    change_column :conversations, :cached_label_list, :string
  end

  private

  # Truncate the list to 255 characters or less
  # by removing the last element until the length is less than 255
  def truncate_list(label_list)
    labels = label_list.split(',')

    # we add the `labels.length - 1` to account for the commas
    labels.pop while (labels.join(',').length + labels.length - 1) > 255

    labels.join(',')
  end
end
