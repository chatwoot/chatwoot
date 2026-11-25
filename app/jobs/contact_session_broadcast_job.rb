# ActionCableBroadcastJob for contact sessions of the Client API, which get the contact's copy of a
# conversation (see ActionCableListener#broadcast_to_client_sessions). The parent's refresh keeps
# the keys it was handed, which narrows the top level but not what is nested in it: the messages
# embed the conversation's assignee. So the refreshed payload is narrowed again.
class ContactSessionBroadcastJob < ActionCableBroadcastJob
  private

  def refreshed_data(conversation, event_name, data)
    Conversations::EventDataPresenter.contact_slice(super).merge(account_id: data[:account_id])
  end
end
