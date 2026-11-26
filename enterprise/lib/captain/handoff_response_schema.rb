# Used for accounts with the captain_reply_handoff feature. The required handoff field records a handoff the model
# has decided on even when it replies instead of calling the handoff tool.
class Captain::HandoffResponseSchema < Captain::ResponseSchema
  define_response_fields(handoff: true)
end
