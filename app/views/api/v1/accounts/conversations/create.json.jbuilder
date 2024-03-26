json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: @conversation if params[:bulk_contacts].blank?
