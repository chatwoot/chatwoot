module Minitest
  ##
  # Compresses backtraces.

  module Compress

    ##
    # Takes a backtrace (array of strings) and compresses repeating
    # cycles in it to make it more readable.

    def compress orig
      ary = orig

      eswo = ->(a, n, off) { # each_slice_with_offset
        if off.zero? then
          a.each_slice n
        else
          # [ ...off... [...n...] [...n...] ... ]
          front, back = a.take(off), a.drop(off)
          [front].chain back.each_slice n
        end
      }

      3.times do # maybe don't use loop do here?
        index = ary                               # [ a b c b c b c d ]
          .size
          .times                                  # 0...size
          .group_by { |i| ary[i] }                # { a: [0] b: [1 3 5], c: [2 4 6], d: [7] }

        order = index
          .reject { |k, v| v.size == 1 }          # { b: [1 3 5], c: [2 4 6] }
          .sort_by { |k, a1|                      ### sort by max dist + min offset
            d = a1.each_cons(2).sum { |a2, b| b-a2 }
            [-d, a1.first]
          }                                       # b: [1 3 5] c: [2 4 6]

        ranges = order
          .map { |k, a1|                          # [[1..2 3..4] [2..3 4..5]]
            a1
              .each_cons(2)
              .map { |a2, b| a2..b-1 }
          }

        big_ranges = ranges
          .flat_map { |a|                         # [1..2 3..4 2..3 4..5]
            a.sort_by { |r| [-r.size, r.first] }.first 5
          }
          .first(100)

        culprits = big_ranges
          .map { |r|
            eswo[ary, r.size, r.begin]            # [o1 s1 s1 s2 s2]
              .chunk_while { |a, b| a == b }      # [[o1] [s1 s1] [s2 s2]]
              .map { |a| [a.size, a.first] }      # [[1 o1] [2 s1] [2 s2]]
          }
          .select { |chunks|
            chunks.any? { |a| a.first > 1 }       # compressed anything?
          }

        min = culprits
          .min_by { |a| a.flatten.size }          # most compressed

        break unless min

        ary = min.flat_map { |(n, lines)|
          if n > 1 then
            [[n, compress(lines)]]                # [o1 [2 s1] [2 s2]]
          else
            lines
          end
        }
      end

      format = ->(lines) {
        lines.flat_map { |line|
          case line
          when Array then
            n, lines = line
            lines = format[lines]
            [
              " +->> #{n} cycles of #{lines.size} lines:",
              *lines.map { |s| " | #{s}" },
              " +-<<",
            ]
          else
            line
          end
        }
      }

      format[ary]
    end
  end
end
