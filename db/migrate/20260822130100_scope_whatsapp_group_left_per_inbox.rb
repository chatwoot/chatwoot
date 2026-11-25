# `group_left` was one boolean on a contact every inbox in the group shares, so it could
# only say "left", never "left where". It moves to the contact inbox, which is the row
# the fact is actually about.
#
# The seed has to give an answer for a row written under the old rule, and the only
# honest one is "all of them": that is what the boolean meant to every reader at the
# time, so every existing group keeps rendering exactly as it does today. The single
# inbox case, which is nearly all of them, is exact rather than merely unchanged.
#
# The old key is then removed, and the removal is what makes the transition safe to read:
# after this runs, a truthy `group_left` on a contact can only have been written by a
# worker from the previous release, which is the window `ContactInbox#group_left?` reads
# it in.
class ScopeWhatsappGroupLeftPerInbox < ActiveRecord::Migration[7.1]
  GROUP_CONTACT = 1

  def up
    left = contact_class.where(group_type: GROUP_CONTACT).where("additional_attributes ->> 'group_left' = 'true'")
    left.find_each do |contact|
      contact_inbox_class.where(contact_id: contact.id).update_all(group_left_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      contact.update_column(:additional_attributes, contact.additional_attributes.except('group_left')) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Puts back what the boolean said, from the rows that now say it. "Left somewhere"
  # collapses to "left", which is the only thing the old shape could express.
  def down
    contact_inbox_class.where.not(group_left_at: nil).distinct.pluck(:contact_id).each do |contact_id|
      contact = contact_class.find_by(id: contact_id)
      next if contact.nil?

      contact.update_column(:additional_attributes, contact.additional_attributes.merge('group_left' => true)) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  def contact_class
    @contact_class ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'contacts'
      self.inheritance_column = :_type_disabled
    end
  end

  def contact_inbox_class
    @contact_inbox_class ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'contact_inboxes'
      self.inheritance_column = :_type_disabled
    end
  end
end
