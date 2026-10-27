# Removes the links in a draft answer that no known text contains, so every link Copilot shows comes from a tool result,
# a message or the instructions, the way Captain's citations take their URLs from the documents a reply used. A markdown
# link with an unknown target keeps its text, and an unknown bare URL is removed. A chart marker written as a link keeps
# its brackets, so its chart is still attached.
class Captain::Copilot::LinkCheck
  # A markdown link, or a bare URL without its closing punctuation.
  LINK = %r{\[([^\]]*)\]\(([^)\s]+)\)|(https?://[^\s<>()\[\]]*[^\s<>()\[\].,;:!?'"])}

  def initialize(known_texts, run_id:)
    @known = known_texts.join("\n")
    @run_id = run_id
  end

  def strip(draft)
    removed = []
    content = draft.gsub(LINK) do |link|
      text, target, url = Regexp.last_match.captures
      next link if @known.include?(target || url)

      removed << (target || url)
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
