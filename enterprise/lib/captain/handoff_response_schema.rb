# Used for customer replies. The required handoff field records whether the reply tells the customer that a person is
# taking over. Captain only logs it for now; the field does not change what happens to the conversation.
class Captain::HandoffResponseSchema < Captain::ResponseSchema
  define_response_fields(handoff: true)
end
