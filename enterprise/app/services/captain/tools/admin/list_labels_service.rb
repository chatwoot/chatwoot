class Captain::Tools::Admin::ListLabelsService < Captain::Tools::Admin::BaseTool
  def self.name
    'list_labels'
  end

  description 'List all labels configured for the account'
  param :search, type: :string, desc: 'Optional filter by label title (partial match)'

  def execute(search: nil)
    labels = account.labels
    labels = labels.where('title ILIKE ?', "%#{search.downcase}%") if search.present?

    return 'No labels found' if labels.none?

    labels.limit(100).map { |label| format_label(label) }.join("\n---\n")
  end
end
