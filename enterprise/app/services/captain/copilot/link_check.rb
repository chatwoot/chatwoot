# Removes the links in a draft answer that no known text contains, so every link Copilot shows comes from a tool result,
# a message or the instructions. A chart marker written as a link keeps its brackets, so its chart is still attached.
class Captain::Copilot::LinkCheck
  # A markdown link, or a bare URL without its closing punctuation.
  LINK = %r{\[([^\]]*)\]\(([^)\s]+)\)|(https?://[^\s<>()\[\]]*[^\s<>()\[\].,;:!?'"])}
  # The tools link to dashboard pages by path and to help center articles and sources by full URL. Any other target, such
  # as a word the instructions contain, is not a link the agent can open.
  TARGET = %r{\A(?:/app/accounts/|https?://)}

  def initialize(known_texts, run_id:)
    @known = known_texts.join("\n")
    @run_id = run_id
  end

  def strip(draft)
    removed = []
    content = draft.gsub(LINK) do |link|
      text, target, url = Regexp.last_match.captures
      found = target || url
      # A known link must end where this one ends, so conversations/12 does not pass because conversations/123 is known.
      next link if found.match?(TARGET) && @known.match?(/#{Regexp.escape(found)}(?![\w-])/)

      removed << found
      url ? '' : unlinked(text)
    end
    Rails.logger.info "[Copilot] run #{@run_id} removed #{removed.size} unknown links: #{removed.join(', ')}" if removed.any?
    content
  end

  private

  def unlinked(text)
    marker = "[#{text}]"
    marker.match?(Captain::Copilot::Chart::MARKER) ? marker : text
  end
end
