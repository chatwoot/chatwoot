# frozen_string_literal: true

require "diff/lcs/block"

# A Hunk is a group of Blocks which overlap because of the context surrounding
# each block. (So if we're not using context, every hunk will contain one
# block.) Used in the diff program (bin/ldiff).
class Diff::LCS::Hunk
  OLD_DIFF_OP_ACTION = {"+" => "a", "-" => "d", "!" => "c"}.freeze # :nodoc:
  ED_DIFF_OP_ACTION = {"+" => "a", "-" => "d", "!" => "c"}.freeze # :nodoc:

  private_constant :OLD_DIFF_OP_ACTION, :ED_DIFF_OP_ACTION if respond_to?(:private_constant)

  # Create a hunk using references to both the old and new data, as well as the
  # piece of data.
  def initialize(data_old, data_new, piece, flag_context, file_length_difference)
    # At first, a hunk will have just one Block in it
    @blocks = [Diff::LCS::Block.new(piece)]

    if @blocks[0].remove.empty? && @blocks[0].insert.empty?
      fail "Cannot build a hunk from #{piece.inspect}; has no add or remove actions"
    end

    if String.method_defined?(:encoding)
      @preferred_data_encoding = data_old.fetch(0) { data_new.fetch(0, "") }.encoding
    end

    @data_old = data_old
    @data_new = data_new

    before = after = file_length_difference
    after += @blocks[0].diff_size
    @file_length_difference = after # The caller must get this manually
    @max_diff_size = @blocks.map { |e| e.diff_size.abs }.max

    # Save the start & end of each array. If the array doesn't exist (e.g.,
    # we're only adding items in this block), then figure out the line number
    # based on the line number of the other file and the current difference in
    # file lengths.
    if @blocks[0].remove.empty?
      a1 = a2 = nil
    else
      a1 = @blocks[0].remove[0].position
      a2 = @blocks[0].remove[-1].position
    end

    if @blocks[0].insert.empty?
      b1 = b2 = nil
    else
      b1 = @blocks[0].insert[0].position
      b2 = @blocks[0].insert[-1].position
    end

    @start_old = a1 || (b1 - before)
    @start_new = b1 || (a1 + before)
    @end_old = a2 || (b2 - after)
    @end_new = b2 || (a2 + after)

    self.flag_context = flag_context
  end

  attr_reader :blocks
  attr_reader :start_old, :start_new
  attr_reader :end_old, :end_new
  attr_reader :file_length_difference

  # Change the "start" and "end" fields to note that context should be added
  # to this hunk.
  attr_accessor :flag_context
  undef :flag_context=
  def flag_context=(context) # :nodoc: # standard:disable Lint/DuplicateMethods
    return if context.nil? || context.zero?

    add_start = (context > @start_old) ? @start_old : context

    @start_old -= add_start
    @start_new -= add_start

    old_size = @data_old.size

    add_end =
      if (@end_old + context) > old_size
        old_size - @end_old
      else
        context
      end

    add_end = @max_diff_size if add_end >= old_size

    @end_old += add_end
    @end_new += add_end
  end

  # Merges this hunk and the provided hunk together if they overlap. Returns
  # a truthy value so that if there is no overlap, you can know the merge
  # was skipped.
  def merge(hunk)
    return unless overlaps?(hunk)

    @start_old = hunk.start_old
    @start_new = hunk.start_new
    blocks.unshift(*hunk.blocks)
  end
  alias_method :unshift, :merge

  # Determines whether there is an overlap between this hunk and the
  # provided hunk. This will be true if the difference between the two hunks
  # start or end positions is within one position of each other.
  def overlaps?(hunk)
    hunk and (((@start_old - hunk.end_old) <= 1) or
              ((@start_new - hunk.end_new) <= 1))
  end

  # Returns a diff string based on a format.
  def diff(format, last = false)
    case format
    when :old
      old_diff(last)
    when :unified
      unified_diff(last)
    when :context
      context_diff(last)
    when :ed
      self
    when :reverse_ed, :ed_finish
      ed_diff(format, last)
    else
      fail "Unknown diff format #{format}."
    end
  end

  # Note that an old diff can't have any context. Therefore, we know that
  # there's only one block in the hunk.
  def old_diff(_last = false)
    warn "Expecting only one block in an old diff hunk!" if @blocks.size > 1

    block = @blocks[0]

    # Calculate item number range. Old diff range is just like a context
    # diff range, except the ranges are on one line with the action between
    # them.
    s = encode("#{context_range(:old, ",")}#{OLD_DIFF_OP_ACTION[block.op]}#{context_range(:new, ",")}\n")
    # If removing anything, just print out all the remove lines in the hunk
    # which is just all the remove lines in the block.
    unless block.remove.empty?
      @data_old[@start_old..@end_old].each { |e| s << encode("< ") + e.chomp + encode("\n") }
    end

    s << encode("---\n") if block.op == "!"

    unless block.insert.empty?
      @data_new[@start_new..@end_new].each { |e| s << encode("> ") + e.chomp + encode("\n") }
    end

    s
  end
  private :old_diff

  def unified_diff(last = false)
    # Calculate item number range.
    s = encode("@@ -#{unified_range(:old, last)} +#{unified_range(:new, last)} @@\n")

    # Outlist starts containing the hunk of the old file. Removing an item
    # just means putting a '-' in front of it. Inserting an item requires
    # getting it from the new file and splicing it in. We splice in
    # +num_added+ items. Remove blocks use +num_added+ because splicing
    # changed the length of outlist.
    #
    # We remove +num_removed+ items. Insert blocks use +num_removed+
    # because their item numbers -- corresponding to positions in the NEW
    # file -- don't take removed items into account.
    lo, hi, num_added, num_removed = @start_old, @end_old, 0, 0

    # standard:disable Performance/UnfreezeString
    outlist = @data_old[lo..hi].map { |e| String.new("#{encode(" ")}#{e.chomp}") }
    # standard:enable Performance/UnfreezeString

    last_block = blocks[-1]

    if last
      old_missing_newline = missing_last_newline?(@data_old)
      new_missing_newline = missing_last_newline?(@data_new)
    end

    @blocks.each do |block|
      block.remove.each do |item|
        op = item.action.to_s # -
        offset = item.position - lo + num_added
        outlist[offset][0, 1] = encode(op)
        num_removed += 1
      end

      if last && block == last_block && old_missing_newline && !new_missing_newline
        outlist << encode('\\ No newline at end of file')
        num_removed += 1
      end

      block.insert.each do |item|
        op = item.action.to_s # +
        offset = item.position - @start_new + num_removed
        outlist[offset, 0] = encode(op) + @data_new[item.position].chomp
        num_added += 1
      end
    end

    outlist << encode('\\ No newline at end of file') if last && new_missing_newline

    s << outlist.join(encode("\n"))

    s
  end
  private :unified_diff

  def context_diff(last = false)
    s = encode("***************\n")
    s << encode("*** #{context_range(:old, ",", last)} ****\n")
    r = context_range(:new, ",", last)

    if last
      old_missing_newline = missing_last_newline?(@data_old)
      new_missing_newline = missing_last_newline?(@data_new)
    end

    # Print out file 1 part for each block in context diff format if there
    # are any blocks that remove items
    lo, hi = @start_old, @end_old
    removes = @blocks.reject { |e| e.remove.empty? }

    unless removes.empty?
      # standard:disable Performance/UnfreezeString
      outlist = @data_old[lo..hi].map { |e| String.new("#{encode("  ")}#{e.chomp}") }
      # standard:enable Performance/UnfreezeString

      last_block = removes[-1]

      removes.each do |block|
        block.remove.each do |item|
          outlist[item.position - lo][0, 1] = encode(block.op) # - or !
        end

        if last && block == last_block && old_missing_newline
          outlist << encode('\\ No newline at end of file')
        end
      end

      s << outlist.join(encode("\n")) << encode("\n")
    end

    s << encode("--- #{r} ----\n")
    lo, hi = @start_new, @end_new
    inserts = @blocks.reject { |e| e.insert.empty? }

    unless inserts.empty?
      # standard:disable Performance/UnfreezeString
      outlist = @data_new[lo..hi].map { |e| String.new("#{encode("  ")}#{e.chomp}") }
      # standard:enable Performance/UnfreezeString

      last_block = inserts[-1]

      inserts.each do |block|
        block.insert.each do |item|
          outlist[item.position - lo][0, 1] = encode(block.op) # + or !
        end

        if last && block == last_block && new_missing_newline
          outlist << encode('\\ No newline at end of file')
        end
      end
      s << outlist.join(encode("\n"))
    end

    s
  end
  private :context_diff

  def ed_diff(format, _last = false)
    warn "Expecting only one block in an old diff hunk!" if @blocks.size > 1

    s =
      if format == :reverse_ed
        encode("#{ED_DIFF_OP_ACTION[@blocks[0].op]}#{context_range(:old, ",")}\n")
      else
        encode("#{context_range(:old, " ")}#{ED_DIFF_OP_ACTION[@blocks[0].op]}\n")
      end

    unless @blocks[0].insert.empty?
      @data_new[@start_new..@end_new].each do |e|
        s << e.chomp + encode("\n")
      end
      s << encode(".\n")
    end
    s
  end
  private :ed_diff

  # Generate a range of item numbers to print. Only print 1 number if the
  # range has only one item in it. Otherwise, it's 'start,end'
  def context_range(mode, op, last = false)
    case mode
    when :old
      s, e = (@start_old + 1), (@end_old + 1)
    when :new
      s, e = (@start_new + 1), (@end_new + 1)
    end

    e -= 1 if last
    e = 1 if e.zero?

    (s < e) ? "#{s}#{op}#{e}" : e.to_s
  end
  private :context_range

  # Generate a range of item numbers to print for unified diff. Print number
  # where block starts, followed by number of lines in the block
  # (don't print number of lines if it's 1)
  def unified_range(mode, last)
    case mode
    when :old
      s, e = (@start_old + 1), (@end_old + 1)
    when :new
      s, e = (@start_new + 1), (@end_new + 1)
    end

    length = e - s + (last ? 0 : 1)

    first = (length < 2) ? e : s # "strange, but correct"
    (length <= 1) ? first.to_s : "#{first},#{length}"
  end
  private :unified_range

  def missing_last_newline?(data)
    newline = encode("\n")

    if data[-2]
      data[-2].end_with?(newline) && !data[-1].end_with?(newline)
    elsif data[-1]
      !data[-1].end_with?(newline)
    else
      true
    end
  end

  if String.method_defined?(:encoding)
    def encode(literal, target_encoding = @preferred_data_encoding)
      literal.encode target_encoding
    end

    def encode_as(string, *args)
      args.map { |arg| arg.encode(string.encoding) }
    end
  else
    def encode(literal, _target_encoding = nil)
      literal
    end

    def encode_as(_string, *args)
      args
    end
  end

  private :encode
  private :encode_as
end
