class BackfillCaptainDocumentHelpCenterArticleIds < ActiveRecord::Migration[7.0]
  def up
    return unless ChatwootApp.enterprise?

    Captain::Document.find_each do |document|
      document.send(:set_help_center_article_id)
      next unless document.will_save_change_to_metadata?

      # rubocop:disable Rails/SkipsModelValidations
      document.update_column(:metadata, document.metadata)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    return unless ChatwootApp.enterprise?

    # rubocop:disable Rails/SkipsModelValidations
    Captain::Document.where("metadata ? 'help_center_article_id'").in_batches do |batch|
      batch.update_all("metadata = metadata - 'help_center_article_id'")
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
