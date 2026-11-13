# Raised from a tool call that started a background run, so the parent run stops without recording a tool result.
class Captain::Copilot::BackgroundRunPending < StandardError
end
