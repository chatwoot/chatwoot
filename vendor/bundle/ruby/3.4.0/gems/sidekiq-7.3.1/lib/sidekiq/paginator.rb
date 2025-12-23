# frozen_string_literal: true

module Sidekiq
  module Paginator
    def page(key, pageidx = 1, page_size = 25, opts = nil)
      current_page = (pageidx.to_i < 1) ? 1 : pageidx.to_i
      pageidx = current_page - 1
      total_size = 0
      items = []
      starting = pageidx * page_size
      ending = starting + page_size - 1

      Sidekiq.redis do |conn|
        type = conn.type(key)
        rev = opts && opts[:reverse]

        case type
        when "zset"
          total_size, items = conn.multi { |transaction|
            transaction.zcard(key)
            if rev
              transaction.zrange(key, starting, ending, "REV", "withscores")
            else
              transaction.zrange(key, starting, ending, "withscores")
            end
          }
          [current_page, total_size, items]
        when "list"
          total_size, items = conn.multi { |transaction|
            transaction.llen(key)
            if rev
              transaction.lrange(key, -ending - 1, -starting - 1)
            else
              transaction.lrange(key, starting, ending)
            end
          }
          items.reverse! if rev
          [current_page, total_size, items]
        when "none"
          [1, 0, []]
        else
          raise "can't page a #{type}"
        end
      end
    end

    def page_items(items, pageidx = 1, page_size = 25)
      current_page = (pageidx.to_i < 1) ? 1 : pageidx.to_i
      pageidx = current_page - 1
      starting = pageidx * page_size
      items = items.to_a
      [current_page, items.size, items[starting, page_size]]
    end
  end
end
