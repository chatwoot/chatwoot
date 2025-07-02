module Captain::Tools::PdfContentChunkingConcern
  extend ActiveSupport::Concern

  private

  def chunk_content(page_contents, max_chunk_size: self.class::MAX_CHUNK_SIZE)
    return [] if page_contents.blank?

    all_chunks = []
    total_page_chunks = 0

    # First pass: calculate total chunks across all pages
    page_contents.each do |page_content|
      page_chunks = split_content_into_chunks(page_content[:content], max_chunk_size)
      total_page_chunks += page_chunks.length
    end

    chunk_index = 0
    page_contents.each do |page_content|
      page_chunks = split_content_into_chunks(page_content[:content], max_chunk_size)

      page_chunks.each do |chunk_content|
        chunk_index += 1
        all_chunks << build_chunk(chunk_content, page_content[:page_number], chunk_index, total_page_chunks)
      end
    end

    all_chunks
  end

  def split_content_into_chunks(content, max_size)
    return [content] if content.length <= max_size

    paragraphs = content.split(/\n\s*\n/)
    chunks = []
    current_chunk = ''

    paragraphs.each do |paragraph|
      if paragraph.length > max_size
        add_chunk_if_present(chunks, current_chunk)
        chunks.concat(split_paragraph_into_chunks(paragraph, max_size))
        current_chunk = ''
      elsif ("#{current_chunk}\n\n#{paragraph}").length > max_size
        add_chunk_if_present(chunks, current_chunk)
        current_chunk = paragraph
      else
        current_chunk = current_chunk.blank? ? paragraph : "#{current_chunk}\n\n#{paragraph}"
      end
    end

    add_chunk_if_present(chunks, current_chunk)
    chunks.presence || [content]
  end

  def split_paragraph_into_chunks(paragraph, max_size)
    sentences = paragraph.split(/(?<=[.!?])\s+/)
    chunks = []
    current_chunk = ''

    sentences.each do |sentence|
      if sentence.length > max_size
        add_chunk_if_present(chunks, current_chunk)
        chunks << sentence[0, max_size]
        current_chunk = ''
      elsif ("#{current_chunk} #{sentence}").length > max_size
        add_chunk_if_present(chunks, current_chunk)
        current_chunk = sentence
      else
        current_chunk = current_chunk.blank? ? sentence : "#{current_chunk} #{sentence}"
      end
    end

    add_chunk_if_present(chunks, current_chunk)
    chunks
  end

  def add_chunk_if_present(chunks, chunk)
    chunks << chunk.strip if chunk.present?
  end

  def build_chunk(content, page_number, chunk_index, total_chunks)
    {
      content: content,
      page_number: page_number,
      chunk_index: chunk_index,
      total_chunks: total_chunks
    }
  end
end