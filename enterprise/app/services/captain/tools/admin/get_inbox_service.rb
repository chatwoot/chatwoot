class Captain::Tools::Admin::GetInboxService < Captain::Tools::Admin::BaseTool
  def self.name
    'get_inbox'
  end

  description 'Get detailed settings for a specific inbox'
  param :inbox_id, type: :integer, desc: 'ID of the inbox to retrieve', required: true

  def execute(inbox_id:)
    inbox = account.inboxes.find_by(id: inbox_id)
    return 'Inbox not found' if inbox.blank?

    format_inbox(inbox)
  end
end
