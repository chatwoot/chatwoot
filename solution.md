# Captain Handoff Activity Message – Proposed Fix

When the Captain assistant triggers a handoff, we need two things to happen reliably:
1. Persist the conversation status change from `pending` to `open`.
2. Attribute that state change to the assistant so the existing activity callback emits the “Captain opened” message.

The clean approach is to give `Conversation` a helper (e.g., `handoff_by(executor)`) that wraps the status update in a `with_executed_by(executor)` block:

```ruby
def handoff_by(executor)
  with_executed_by(executor) do
    open! unless open?
    dispatcher_dispatch(CONVERSATION_BOT_HANDOFF)
  end
end
```

Within that helper, `with_executed_by` should set `Current.executed_by` just for the duration of the update and then restore the previous value. Both the V1 handoff path and the Captain tool call this helper, ensuring the status change is tracked and the enterprise override sees the assistant.

## Why Not Store `Current.handoff_requested?`

Using a thread-local flag would mean the tool sets `Current.handoff_requested = true` and hopes the job checks it later. That requires carefully clearing the flag on every execution path, and it leaves state lingering on `Current` while unrelated callbacks run. It’s easy to forget the cleanup and leak the flag into subsequent jobs or observers. By contrast, a push/pop around the actual update keeps responsibility localized and avoids coordination hazards.
