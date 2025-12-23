# frozen_string_literal: true

module Byebug
  #
  # Reopens the +info+ command to define the +breakpoints+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about current breakpoints
    #
    class BreakpointsCommand < Command
      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* b(?:reakpoints)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-DESCRIPTION
          inf[o] b[reakpoints]

          #{short_description}
        DESCRIPTION
      end

      def self.short_description
        "Status of user settable breakpoints"
      end

      def execute
        return puts("No breakpoints.") if Byebug.breakpoints.empty?

        breakpoints = Byebug.breakpoints.sort_by(&:id)

        if @match[1]
          indices = @match[1].split(/ +/).map(&:to_i)
          breakpoints = breakpoints.select { |b| indices.member?(b.id) }
          return errmsg("No breakpoints found among list given") if breakpoints.empty?
        end

        puts "Num Enb What"
        breakpoints.each { |b| info_breakpoint(b) }
      end

      private

      def info_breakpoint(brkpt)
        interp = format(
          "%-<id>3d %-<status>3s at %<file>s:%<line>s%<expression>s",
          id: brkpt.id,
          status: brkpt.enabled? ? "y" : "n",
          file: brkpt.source,
          line: brkpt.pos,
          expression: brkpt.expr.nil? ? "" : " if #{brkpt.expr}"
        )
        puts interp
        hits = brkpt.hit_count
        return unless hits.positive?

        s = hits > 1 ? "s" : ""
        puts "  breakpoint already hit #{hits} time#{s}"
      end
    end
  end
end
