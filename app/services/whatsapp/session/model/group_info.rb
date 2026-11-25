# A WhatsApp group as the provider describes it. Feeds the group syncer, which keeps the
# group contact, its avatar and its participant list in sync.
class Whatsapp::Session::Model::GroupInfo < Data.define(
  :group, :subject, :description, :topic_id, :owner, :created_at, :participants, :size,
  :announce, :locked, :join_approval, :member_add_mode, :picture_url, :has_picture, :invite_code
)
  include Whatsapp::Session::Model::Serializable

  # `topic_id` frozen at this exact string is what says the description can never be
  # changed again. WhatsApp answers every edit of such a group with a conflict, whatever
  # the stanza looks like, and a conflict on its own is ambiguous: another admin writing
  # between the read and the write produces the same answer. So the provider passes the
  # raw reading on and the decision of what to tell the operator is made here.
  #
  # Only this value means it. A `topic_id` that is absent means the provider does not
  # report one -- uazapi never does -- and absent is not the same claim as frozen: saying
  # a description cannot be changed where it can leaves the operator with no way to do
  # something they are allowed to do.
  FROZEN_TOPIC_ID = 'undefined'.freeze

  # A member of a group and the role WhatsApp gave them.
  class Participant < Data.define(:party, :role)
    include Whatsapp::Session::Model::Serializable
    coerce party: Whatsapp::Session::Model::Party
    defaults role: 'member'

    ROLES = %w[member admin superadmin].freeze

    def admin?
      role.in?(%w[admin superadmin])
    end
  end

  coerce group: Whatsapp::Session::Model::Address,
         owner: Whatsapp::Session::Model::Party,
         participants: [Participant]
  # No default for the settings: they are optional on the wire, and defaulting them to
  # false makes a snapshot that simply did not report one indistinguishable from one
  # reporting it off, which is enough for a sync to silently disable it.
  defaults participants: []

  def admins
    Array(participants).select(&:admin?)
  end

  # Whether WhatsApp will refuse every description edit for this group, as far as this
  # snapshot can tell. False for a provider that does not report the field at all.
  def description_frozen?
    topic_id == FROZEN_TOPIC_ID
  end
end
