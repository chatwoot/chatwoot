# frozen_string_literal: true

# Manages tags for contacts during data import.
class DataImport::TagsManager
  def initialize(account)
    @account = account
    @valid_tags = @account.labels.pluck(:title).map(&:downcase)
  end

  def build(params)
    return [] if params[:tags].blank?

    contact = find_existing_contact(params)
    return [] if contact.blank?

    tags = normalize_tags(params[:tags])
    return [] if tags.blank?

    initialize_tag(contact, tags)
  end

  private

  def initialize_tag(contact, tags)
    labels = Label.where(account_id: @account.id, title: tags).pluck(:title)
    return [] if labels.empty?

    acts_tags = ActsAsTaggableOn::Tag.where(name: labels)

    acts_tags.filter_map do |acts_tag|
      ActsAsTaggableOn::Tagging.new(
        tag_id: acts_tag.id,
        taggable_id: contact.id,
        taggable_type: 'Contact',
        context: 'labels'
      )
    end
  end

  def find_existing_contact(params)
    return @account.contacts.find_by(identifier: params[:identifier]) if params[:identifier].present?
    return @account.contacts.from_email(params[:email]) if params[:email].present?
    return @account.contacts.find_by(phone_number: formatted_phone(params[:phone_number])) if params[:phone_number].present?

    nil
  end

  def formatted_phone(phone_number)
    return if phone_number.blank?

    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def fetch_valid_tags(new_tags)
    tags = normalize_tags(new_tags)

    @valid_tags & tags
  end

  def normalize_tags(tags_string)
    tags_string.to_s.split(',').map { |tag| tag.strip.downcase }.reject(&:empty?)
  end
end
