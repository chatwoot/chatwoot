# frozen_string_literal: true

module TestProf
  # Extend String with #truncate method
  module StringTruncate
    refine String do
      # Truncate to the specified limit
      # by replacing middle part with dots
      def truncate(limit = 30)
        return self unless size > limit

        head = ((limit - 3) / 2)
        tail = head + 3 - limit

        "#{self[0..(head - 1)]}...#{self[tail..-1]}"
      end
    end
  end
end
