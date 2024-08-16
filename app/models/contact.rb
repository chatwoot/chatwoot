# rubocop:disable Layout/LineLength

# == Schema Information
#
# Table name: contacts
#
#  id                     :integer          not null, primary key
#  additional_attributes  :jsonb
#  blocked                :boolean          default(FALSE), not null
#  contact_type           :integer          default("visitor")
#  country_code           :string           default("")
#  custom_attributes      :jsonb
#  email                  :string
#  first_reply_created_at :datetime
#  identifier             :string
#  initial_channel_type   :string
#  last_activity_at       :datetime
#  last_name              :string           default("")
#  last_stage_changed_at  :datetime
#  location               :string           default("")
#  middle_name            :string           default("")
#  name                   :string           default("")
#  phone_number           :string
#  po_date                :datetime
#  po_note                :string
#  po_value               :float
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  assignee_id            :integer
#  initial_channel_id     :integer
#  product_id             :integer
#  stage_id               :integer
#  team_id                :integer
#
# Indexes
#
#  index_contacts_on_account_id                          (account_id)
#  index_contacts_on_blocked                             (blocked)
#  index_contacts_on_lower_email_account_id              (lower((email)::text), account_id)
#  index_contacts_on_name_email_phone_number_identifier  (name,email,phone_number,identifier) USING gin
#  index_contacts_on_nonempty_fields                     (account_id,email,phone_number,identifier) WHERE (((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))
#  index_contacts_on_phone_number_and_account_id         (phone_number,account_id)
#  index_resolved_contact_account_id                     (account_id) WHERE (((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))
#  uniq_email_per_account_contact                        (email,account_id) UNIQUE
#  uniq_identifier_per_account_contact                   (identifier,account_id) UNIQUE
#

# rubocop:enable Layout/LineLength

class Contact < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Avatarable
  include AvailabilityStatusable
  include Labelable

  validates :account_id, presence: true
  validates :email, allow_blank: true, uniqueness: { scope: [:account_id], case_sensitive: false },
                    format: { with: Devise.email_regexp, message: I18n.t('errors.contacts.email.invalid') }
  validates :identifier, allow_blank: true, uniqueness: { scope: [:account_id] }
  validates :phone_number,
            allow_blank: true, uniqueness: { scope: [:account_id] },
            format: { with: /\+[1-9]\d{1,14}\z/, message: I18n.t('errors.contacts.phone_number.invalid') }

  belongs_to :account
  belongs_to :stage, optional: true
  belongs_to :product, optional: true
  belongs_to :team, optional: true
  belongs_to :assignee, class_name: 'User', optional: true, inverse_of: :assigned_contacts
  belongs_to :initial_channel,
             class_name: :Channel,
             optional: true
  has_many :conversations, dependent: :destroy_async
  has_many :contact_inboxes, dependent: :destroy_async
  has_many :csat_survey_responses, dependent: :destroy_async
  has_many :inboxes, through: :contact_inboxes
  has_many :messages, as: :sender, dependent: :destroy_async
  has_many :notes, dependent: :destroy_async
  has_many :contact_transactions, dependent: :destroy_async
  before_validation :prepare_contact_attributes, :set_default_stage_id
  after_create_commit :dispatch_create_event, :ip_lookup
  after_update_commit :dispatch_update_event, :dispatch_won_event
  after_destroy_commit :dispatch_destroy_event
  before_save :sync_contact_attributes
  after_save :stage_changed_action, if: :saved_change_to_stage_id?
  after_save :po_changed_action, if: :saved_change_to_po_info?

  enum contact_type: { visitor: 0, lead: 1, customer: 2 }

  scope :order_on_last_activity_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"last_activity_at\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_created_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"created_at\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_last_stage_changed_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"last_stage_changed_at\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_updated_at, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"updated_at\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_stage_id, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"stage_id\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_team_id, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"team_id\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_assignee_id, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"assignee_id\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_product_id, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"product_id\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_po_value, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order("\"contacts\".\"po_value\" #{direction}
          NULLS LAST")
      )
    )
  }
  scope :order_on_company_name, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order(
          "\"contacts\".\"additional_attributes\"->>'company_name' #{direction}
          NULLS LAST"
        )
      )
    )
  }
  scope :order_on_city, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order(
          "\"contacts\".\"additional_attributes\"->>'city' #{direction}
          NULLS LAST"
        )
      )
    )
  }
  scope :order_on_country_name, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order(
          "\"contacts\".\"additional_attributes\"->>'country' #{direction}
          NULLS LAST"
        )
      )
    )
  }

  scope :order_on_name, lambda { |direction|
    order(
      Arel::Nodes::SqlLiteral.new(
        sanitize_sql_for_order(
          "CASE
           WHEN \"contacts\".\"name\" ~~* '^+\d*' THEN 'z'
           WHEN \"contacts\".\"name\"  ~~*  '^\b*' THEN 'z'
           ELSE LOWER(\"contacts\".\"name\")
           END #{direction}"
        )
      )
    )
  }

  def get_source_id(inbox_id)
    contact_inboxes.find_by!(inbox_id: inbox_id).source_id
  end

  def push_event_data
    {
      additional_attributes: additional_attributes,
      custom_attributes: custom_attributes,
      email: email,
      id: id,
      identifier: identifier,
      name: name,
      phone_number: phone_number,
      thumbnail: avatar_url,
      type: 'contact'
    }
  end

  def webhook_data
    {
      account: account.webhook_data,
      additional_attributes: additional_attributes,
      avatar: avatar_url,
      custom_attributes: custom_attributes,
      email: email,
      id: id,
      identifier: identifier,
      name: name,
      phone_number: phone_number,
      initial_channel_type: initial_channel_type,
      assignee: assignee&.webhook_data,
      team_name: team&.name,
      stage_code: stage&.code,
      product_short_name: product&.short_name,
      po_date: po_date,
      po_value: po_value,
      po_note: po_note
    }
  end

  def self.resolved_contacts
    # temporarily change to all and consider the condition later
    all
  end

  def discard_invalid_attrs
    phone_number_format
    email_format
  end

  def self.from_email(email)
    find_by(email: email&.downcase)
  end

  private

  def ip_lookup
    return unless account.feature_enabled?('ip_lookup')

    ContactIpLookupJob.perform_later(self)
  end

  def phone_number_format
    return if phone_number.blank?

    self.phone_number = phone_number_was unless phone_number.match?(/\+[1-9]\d{1,14}\z/)
  end

  def email_format
    return if email.blank?

    self.email = email_was unless email.match(Devise.email_regexp)
  end

  def prepare_contact_attributes
    prepare_email_attribute
    prepare_jsonb_attributes
  end

  def set_default_stage_id
    return if stage_id.present?

    new_stage = Stage.find_by(account_id: account_id, code: 'New')
    self.stage_id = new_stage.id if new_stage.present?
  end

  def prepare_email_attribute
    # So that the db unique constraint won't throw error when email is ''
    self.email = email.present? ? email.downcase : nil
  end

  def prepare_jsonb_attributes
    self.additional_attributes = {} if additional_attributes.blank?
    self.custom_attributes = {} if custom_attributes.blank?
  end

  def sync_contact_attributes
    ::Contacts::SyncAttributes.new(self).perform
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(CONTACT_CREATED, Time.zone.now, contact: self)

    return unless stage&.code == 'Won'

    Rails.configuration.dispatcher.dispatch(CONTACT_WON, Time.zone.now, contact: self)
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(CONTACT_UPDATED, Time.zone.now, contact: self, changed_attributes: previous_changes)
  end

  def dispatch_won_event
    return unless saved_change_to_stage_id? && stage.code == 'Won'

    Rails.configuration.dispatcher.dispatch(CONTACT_WON, Time.zone.now, contact: self, changed_attributes: previous_changes)
  end

  def dispatch_destroy_event
    Rails.configuration.dispatcher.dispatch(CONTACT_DELETED, Time.zone.now, contact: self)
  end

  def stage_changed_action
    update_column(:last_stage_changed_at, DateTime.now.utc) # rubocop:disable Rails/SkipsModelValidations
  end

  def saved_change_to_po_info?
    saved_change_to_product_id? ||
      saved_change_to_po_date? ||
      saved_change_to_po_value? ||
      saved_change_to_po_note? ||
      saved_change_to_custom_attributes
  end

  def po_changed_action
    return if product_id.blank? || po_date.blank?

    transaction = contact_transactions.find_or_create_by(account_id: account_id, product_id: product_id, po_date: po_date)

    transaction.update(
      po_value: po_value,
      po_note: po_note,
      custom_attributes: transaction_custom_attributes
    )
  end

  def transaction_custom_attributes
    transaction_ca = {}
    transaction_ca[:branch] = custom_attributes['branch'] if custom_attributes['branch'].present?
    transaction_ca[:expected_time] = custom_attributes['expected_time'] if custom_attributes['expected_time'].present?
    transaction_ca
  end
end
