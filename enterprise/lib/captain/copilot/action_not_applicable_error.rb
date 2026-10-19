# Raised by an action when its change no longer applies to a record, e.g. the channel's reply window has closed. The message
# is saved as the item's error and reported to the model, and the record is not retried.
class Captain::Copilot::ActionNotApplicableError < StandardError
end
