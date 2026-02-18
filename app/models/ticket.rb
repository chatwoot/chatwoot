# frozen_string_literal: true

class Ticket < ApplicationRecord
  belongs_to :account
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true

  has_many_attached :files

  validates :subject, presence: true

  def external_id_for(provider)
    external_ids[provider.to_s]
  end

  def store_external_id(provider, external_id)
    self.external_ids ||= {}
    self.external_ids[provider.to_s] = external_id
    save!
  end
end
