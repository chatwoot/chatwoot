contact_info_requests = Whatsapp::ContactInfoRequestEligibilityService.availability_by_conversation(@conversations)

json.payload do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/conversations/partials/conversation',
                  formats: [:json],
                  conversation: conversation,
                  contact_info_request: contact_info_requests.fetch(conversation.id)
  end
end
