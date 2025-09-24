# frozen_string_literal: true

# Manages tags for contacts during data import.
class DataImport::TagsManager
  def initialize(account)
    @account = account
    @valid_tags = @account.labels.pluck(:title).map(&:downcase)
  end

  def build(params)
    return if params[:tags].blank?

    contact = find_existing_contact(params)
    return if contact.blank?

    tags = normalize_tags(params[:tags])
    contact.add_labels(tags)
  end

  private

  def find_existing_contact(params)
    return if params.blank?

    @account.contacts.find_by(identifier: params[:identifier]) ||
      @account.contacts.from_email(params[:email]) ||
      @account.contacts.find_by(phone_number: formatted_phone(params[:phone_number]))
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
