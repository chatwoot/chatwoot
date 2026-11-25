# Which WhatsApp number a group action is performed as.
#
# A group contact is account-scoped (its identifier is the group's own id), while a
# contact inbox is per inbox, so one WhatsApp group can belong to two inboxes of the same
# account. These requests used to resolve the channel by taking whichever contact inbox
# came first, and the dashboard decides what an agent may do from the inbox they have
# open, so the two could disagree: the panel granted the action using inbox A's
# capabilities and admin status, and the server then performed it as inbox B. Leaving the
# group is the worst of them, because it removes the wrong number from the group.
module GroupChannelResolver
  extend ActiveSupport::Concern

  private

  # The channel a group action runs as, and the only way to get one. It refuses rather than handing
  # back nil for the provider call to raise on: an agent with no claim to any of this group's
  # inboxes was answered 500 for a request that is simply not theirs.
  #
  # There used to be a nil-tolerant reader beside this one, for the roster read, on the grounds
  # that `ContactPolicy` and not inbox membership governs it. What that produced was one endpoint
  # answering the same question two ways: 200 with the roster when the caller left `inbox_id` out,
  # 404 when they named an inbox they are not on. The verdict may not depend on whether an
  # optional parameter was typed, and refusing is what the other eleven group routes already
  # answer (fazer-ai/chatwoot#535).
  #
  # What that costs, said out loud: the roster of a group contact that is in no inbox at all stops
  # being readable. Nothing in the dashboard asks for one -- every caller passes the inbox of the
  # conversation it has open, and an administrator gets every inbox of the account -- so the case
  # is reachable through the API and not through the product.
  def channel
    group_contact_inbox&.inbox&.channel || raise(ActiveRecord::RecordNotFound)
  end

  def group_contact_inbox
    return @group_contact_inbox if defined?(@group_contact_inbox)

    @group_contact_inbox = resolve_group_contact_inbox
  end

  # `inbox_id` is optional, because these endpoints are documented and shipped without it.
  # What it may not be is wrong: an inbox this group does not belong to is refused rather
  # than quietly replaced by another one, which is the substitution this exists to stop.
  #
  # Left out, one inbox answers for itself. Left out on a group that is in two, there is
  # no answer to give, and picking one is the coin flip: the caller is asked to say which.
  #
  # Only inboxes this agent is on are candidates. `ContactPolicy` lets every agent of the
  # account read and update a contact, which was harmless while the inbox was ours to
  # pick; naming one is a request, and without this an agent on inbox A could leave the
  # group, promote or remove members as inbox B by asking for it. An inbox they are not
  # on reads as an inbox the group is not in: refusing it differently would answer
  # whether that number is in the group.
  def resolve_group_contact_inbox
    candidates = @contact.contact_inboxes.includes(:inbox).where(inbox: Current.user.assigned_inboxes)
    return candidates.find_by!(inbox_id: params[:inbox_id]) if params[:inbox_id].present?

    # None and one both answer nil here, and `channel` is what turns that into the refusal. Kept
    # as nil rather than raised here because this method answers which inbox, not whether one
    # exists to answer with.
    return candidates.first if candidates.size <= 1

    raise ActionController::BadRequest, I18n.t('contacts.group.inbox_id_required')
  end
end
