total_count = @conversations_count.fetch(count_key)
has_next_page = @conversations.respond_to?(:current_page) && @conversations.current_page * @conversations.limit_value < total_count

json.next_page has_next_page ? @conversations.current_page + 1 : nil
