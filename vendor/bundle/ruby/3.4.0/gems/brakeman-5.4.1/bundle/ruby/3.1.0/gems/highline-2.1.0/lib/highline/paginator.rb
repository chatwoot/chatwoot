# coding: utf-8

class HighLine
  # Take the task of paginating some piece of text given a HighLine context
  class Paginator
    # @return [HighLine] HighLine context
    attr_reader :highline

    # Returns a HighLine::Paginator instance where you can
    # call {#page_print} on it.
    # @param highline [HighLine] context
    # @example
    #   HighLine::Paginator.new(highline).page_print(statement)
    def initialize(highline)
      @highline = highline
    end

    #
    # Page print a series of at most _page_at_ lines for _output_.  After each
    # page is printed, HighLine will pause until the user presses enter/return
    # then display the next page of data.
    #
    # Note that the final page of _output_ is *not* printed, but returned
    # instead.  This is to support any special handling for the final sequence.
    #
    # @param text [String] text to be paginated
    # @return [String] last line if paging is aborted
    def page_print(text)
      return text unless highline.page_at

      lines = text.lines.to_a
      while lines.size > highline.page_at
        highline.puts lines.slice!(0...highline.page_at).join
        highline.puts
        # Return last line if user wants to abort paging
        return "...\n#{lines.last}" unless continue_paging?
      end
      lines.join
    end

    #
    # Ask user if they wish to continue paging output. Allows them to
    # type "q" to cancel the paging process.
    #
    def continue_paging?
      command = highline.new_scope.ask(
        "-- press enter/return to continue or q to stop -- "
      ) { |q| q.character = true }
      command !~ /\A[qQ]\Z/ # Only continue paging if Q was not hit.
    end
  end
end
