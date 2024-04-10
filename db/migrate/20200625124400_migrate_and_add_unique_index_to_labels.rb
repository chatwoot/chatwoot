class MigrateAndAddUniqueIndexToLabels < ActiveRecord::Migration[6.0]
  def change
    add_index :labels, [:title, :account_id], unique: true
    migrate_existing_tags
  end

  private

  def migrate_existing_tags
    ::ActsAsTaggableOn::Tag.all.each do |tag|
      tag.taggings.each do |tagging|
        ensure_label_for_account(tag.name, tagging.taggable.account)
      end
    end
  end

  def ensure_label_for_account(name, account)
    account.labels.where(title: name.downcase).first_or_create
  end
end
