class Labels::DestroyService
  pattr_initialize [:label_title!, :account_id!, :tagging_ids!]

  def perform
    label_taggings.find_in_batches do |tagging_batch|
      tagging_batch.each do |tagging|
        taggable = tagging.taggable

        next unless taggable
        next unless taggable.account_id == account_id

        taggable.label_list.remove(label_title)
        taggable.save!
      end
    end
  end

  private

  def label_taggings
    @label_taggings ||= ActsAsTaggableOn::Tagging.where(id: tagging_ids)
  end

  def account
    @account ||= Account.find(account_id)
  end
end
