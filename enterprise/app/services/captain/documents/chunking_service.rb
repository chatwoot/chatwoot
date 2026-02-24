class Captain::Documents::ChunkingService
  DEFAULT_TARGET_TOKENS = 600
  DEFAULT_MIN_TOKENS = 400
  DEFAULT_MAX_TOKENS = 800
  DEFAULT_OVERLAP_TOKENS = 120
  BOILERPLATE_SECTION_PATTERNS = [
    /skip to main content/i,
    /table of contents/i,
    /related articles/i,
    /recommended articles/i,
    /need more help/i,
    /contact support/i,
    /cookie/i,
    /privacy policy/i,
    /terms of service/i,
    /all rights reserved/i,
    /back to top/i
  ].freeze
  BOILERPLATE_LINE_PATTERNS = [
    /help center home page/i,
    /theming_assets/i,
    %r{hc/change_language/}i
  ].freeze

  def initialize(content, target_tokens: DEFAULT_TARGET_TOKENS, min_tokens: DEFAULT_MIN_TOKENS,
                 max_tokens: DEFAULT_MAX_TOKENS, overlap_tokens: DEFAULT_OVERLAP_TOKENS)
    @content = content.to_s
    @target_tokens = target_tokens
    @min_tokens = min_tokens
    @max_tokens = max_tokens
    @overlap_tokens = overlap_tokens
  end

  def chunk
    return [] if @content.blank?

    sections = split_into_sections(@content)
    return [] if sections.empty?

    base_chunks = build_chunks(sections)
    apply_overlap(base_chunks).map.with_index do |chunk_content, index|
      {
        position: index,
        content: chunk_content,
        token_count: estimate_tokens(chunk_content)
      }
    end
  end

  private

  Section = Struct.new(:content, :heading_path, keyword_init: true)

  def split_into_sections(content)
    cleaned_content = remove_boilerplate_sections(remove_boilerplate_lines(content))
    heading_path = []

    cleaned_content
      .split(/\n{2,}/)
      .map(&:strip)
      .reject(&:blank?)
      .map do |section_content|
      heading_path = update_heading_path_from_section(heading_path, section_content)
      Section.new(content: section_content, heading_path: heading_path.dup)
    end
  end

  def remove_boilerplate_sections(content)
    content
      .split(/\n{2,}/)
      .map(&:strip)
      .reject(&:blank?)
      .reject { |section| boilerplate_section?(section) }
      .join("\n\n")
  end

  def remove_boilerplate_lines(content)
    content
      .lines
      .reject { |line| boilerplate_line?(line) }
      .join
  end

  def boilerplate_section?(section)
    normalized = section.downcase.strip
    return true if BOILERPLATE_SECTION_PATTERNS.any? { |pattern| normalized.match?(pattern) }

    link_heavy_navigation_section?(section)
  end

  def boilerplate_line?(line)
    normalized = line.to_s.downcase.strip
    return false if normalized.blank?
    return true if BOILERPLATE_LINE_PATTERNS.any? { |pattern| normalized.match?(pattern) }

    markdown_links = normalized.scan(/\[[^\]]+\]\([^)]+\)/).size
    return true if normalized.include?('change_language/') && markdown_links >= 3
    return false unless markdown_links >= 6

    non_link_tokens = normalized
                      .gsub(/\[[^\]]+\]\([^)]+\)/, ' ')
                      .gsub(/[^a-z0-9\s]/, ' ')
                      .squeeze(' ')
                      .strip
                      .split
    non_link_tokens.length <= 12
  end

  def link_heavy_navigation_section?(section)
    lines = section.lines.map(&:strip).reject(&:blank?)
    return false if lines.size < 3

    markdown_links = section.scan(/\[[^\]]+\]\([^)]+\)/).size
    linked_lines = lines.count { |line| link_line?(line) }
    return false unless markdown_links >= 2 && linked_lines >= 3

    section.scan(/\b[\w']+\b/).size <= 180
  end

  def link_line?(line) = line.match?(/\[[^\]]+\]\([^)]+\)/) || line.start_with?('* [', '- [')

  def build_chunks(sections)
    state = { chunks: [], current_chunk: +'', current_tokens: 0 }
    sections.each { |section| process_section(section, state) }
    state[:chunks] << state[:current_chunk] if state[:current_chunk].present?
    state[:chunks]
  end

  def apply_overlap(chunks)
    return chunks if chunks.size <= 1 || @overlap_tokens <= 0

    overlapped = [chunks.first]
    (1...chunks.size).each do |index|
      previous_tail = tail_tokens(chunks[index - 1], @overlap_tokens)
      next_chunk = [previous_tail, chunks[index]].reject(&:blank?).join("\n\n")
      overlapped << next_chunk
    end
    overlapped
  end

  def with_heading_context(section)
    return section.content if section.heading_path.empty?

    heading_line = "Section: #{section.heading_path.join(' > ')}"
    "#{heading_line}\n#{section.content}"
  end

  def heading?(line)
    line.match?(/\A\#{1,6}\s+\S+/)
  end

  def appendable?(current_tokens, section_tokens)
    return true if current_tokens + section_tokens <= @max_tokens
    return false if current_tokens.zero?

    current_tokens < @min_tokens
  end

  def append_to_current_chunk(current_chunk, section_content)
    current_chunk << "\n\n" unless current_chunk.empty?
    current_chunk << section_content
    [current_chunk, estimate_tokens(current_chunk)]
  end

  def process_section(section, state)
    section_content = with_heading_context(section)
    section_tokens = estimate_tokens(section_content)
    should_append = appendable?(state[:current_tokens], section_tokens)

    state[:current_chunk], state[:current_tokens] = if should_append
                                                      append_to_current_chunk(state[:current_chunk], section_content)
                                                    else
                                                      state[:chunks] << state[:current_chunk] if state[:current_chunk].present?
                                                      [section_content.dup, section_tokens]
                                                    end
    flush_target_chunk(state)
  end

  def flush_target_chunk(state)
    return unless state[:current_tokens] >= @target_tokens

    state[:chunks] << state[:current_chunk]
    state[:current_chunk] = +''
    state[:current_tokens] = 0
  end

  def update_heading_path_from_section(path, section_content)
    heading_line = section_content.lines.first.to_s.strip
    return path unless heading?(heading_line)

    update_heading_path(path, heading_line)
  end

  def update_heading_path(path, heading_line)
    level = heading_line[/\A#+/].length
    heading_text = heading_line.sub(/\A#+\s*/, '').strip

    updated_path = path.dup
    updated_path = updated_path.first(level - 1)
    updated_path << heading_text
    updated_path
  end

  def estimate_tokens(text)
    return 0 if text.blank?

    (text.split(/\s+/).length * 1.3).ceil
  end

  def tail_tokens(text, token_budget)
    return '' if text.blank? || token_budget <= 0

    words = text.split(/\s+/)
    tail_word_count = (token_budget / 1.3).ceil
    words.last(tail_word_count).join(' ')
  end
end
