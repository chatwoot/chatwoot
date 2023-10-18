if params[:bulk_contacts].blank?
  json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: @conversation
end
