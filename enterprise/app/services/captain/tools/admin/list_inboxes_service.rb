class Captain::Tools::Admin::ListInboxesService < Captain::Tools::Admin::BaseTool
  def self.name
    'list_inboxes'
  end

  description 'List all inboxes configured for the account'
  param :search, type: :string, desc: 'Optional filter by inbox name (partial match)'

  def execute(search: nil)
    inboxes = account.inboxes
    inboxes = inboxes.where('name ILIKE ?', "%#{search}%") if search.present?

    return 'No inboxes found' if inboxes.none?

    inboxes.limit(100).map { |inbox| format_inbox(inbox) }.join("\n---\n")
  end
end
