# frozen_string_literal: true

# Client for Salesforce Contact API
class Crm::Salesforce::Api::ContactClient < Crm::Salesforce::BaseClient
  # Create a new contact
  #
  # @param contact_data [Hash] Contact data
  # @return [Hash] Response with contact ID
  def create_contact(contact_data)
    request(:post, '/sobjects/Contact', body: contact_data.to_json)
  end

  # Update an existing contact
  #
  # @param contact_id [String] Salesforce Contact ID
  # @param contact_data [Hash] Contact data
  # @return [Hash] Response
  def update_contact(contact_id, contact_data)
    request(:patch, "/sobjects/Contact/#{contact_id}", body: contact_data.to_json)
  end

  # Get contact by ID
  #
  # @param contact_id [String] Salesforce Contact ID
  # @return [Hash] Contact data
  def get_contact(contact_id)
    request(:get, "/sobjects/Contact/#{contact_id}")
  end

  # Search contacts by email
  #
  # @param email [String] Email to search
  # @return [Hash] Search results
  def search_by_email(email)
    escaped = email.to_s.gsub("'", "''")
    query = "SELECT Id, FirstName, LastName, Email, Phone, AccountId FROM Contact WHERE Email = '#{escaped}'"
    request(:get, '/query', query: { q: query })
  end
end
