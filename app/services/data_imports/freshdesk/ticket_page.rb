class DataImports::Freshdesk::TicketPage
  TICKETS_PER_CHUNK = 10

  attr_reader :current_cursor

  def initialize(client:, starting_after:, per_page:)
    @client = client
    @per_page = per_page
    @cursor = normalize_cursor(starting_after)
    @tickets, next_page = ticket_page(per_page)
    @page_limit_reached = page_limit_reached?
    next_page = nil if @page_limit_reached
    @current_cursor = @cursor.merge('tickets' => @tickets, 'next_page' => next_page)
  end

  def chunk
    @chunk ||= @tickets.slice(@cursor['offset'], TICKETS_PER_CHUNK) || []
  end

  def checkpoints
    @checkpoints ||= chunk.each_index.map { |index| cursor_after(index + 1) }
  end

  def next_cursor
    return checkpoints.last if chunk.present?

    cursor_after(0)
  end

  def limit_reached?
    @page_limit_reached && next_cursor.nil?
  end

  private

  def normalize_cursor(starting_after)
    return { 'page' => starting_after.presence || 1, 'offset' => 0 } unless starting_after.is_a?(Hash)

    cursor = starting_after.deep_stringify_keys.slice('page', 'offset', 'tickets', 'next_page')
    cursor.merge('page' => cursor['page'] || 1, 'offset' => cursor['offset'].to_i)
  end

  def ticket_page(per_page)
    return [Array(@cursor['tickets']), @cursor['next_page']] if @cursor.key?('tickets')

    page = @client.list_tickets(page: @cursor['page'], per_page: per_page)
    tickets = Array(page.data).map { |ticket| ticket.slice('id', 'source') }
    [tickets, page.next_page]
  end

  def cursor_after(processed_count)
    next_offset = @cursor['offset'] + processed_count
    return current_cursor.merge('offset' => next_offset) if next_offset < @tickets.size
    return { 'page' => current_cursor['next_page'], 'offset' => 0 } if current_cursor['next_page'].present?

    nil
  end

  def page_limit_reached?
    @cursor['page'].to_i >= DataImports::Freshdesk::Client::MAX_TICKET_PAGES && @tickets.size >= @per_page
  end
end
