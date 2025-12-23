# frozen_string_literal: true

require "optparse"
require "ostruct"
require "diff/lcs/hunk"

module Diff::LCS::Ldiff # :nodoc:
  # standard:disable Layout/HeredocIndentation
  BANNER = <<-COPYRIGHT
ldiff #{Diff::LCS::VERSION}
  Copyright 2004-2019 Austin Ziegler

  Part of Diff::LCS.
  https://github.com/halostatue/diff-lcs

  This program is free software. It may be redistributed and/or modified under
  the terms of the GPL version 2 (or later), the Perl Artistic licence, or the
  MIT licence.
  COPYRIGHT
  # standard:enable Layout/HeredocIndentation
end

class << Diff::LCS::Ldiff
  attr_reader :format, :lines # :nodoc:
  attr_reader :file_old, :file_new # :nodoc:
  attr_reader :data_old, :data_new # :nodoc:

  def run(args, _input = $stdin, output = $stdout, error = $stderr) # :nodoc:
    @binary = nil

    args.options do |o|
      o.banner = "Usage: #{File.basename($0)} [options] oldfile newfile"
      o.separator ""
      o.on(
        "-c", "-C", "--context [LINES]", Integer,
        "Displays a context diff with LINES lines", "of context. Default 3 lines."
      ) do |ctx|
        @format = :context
        @lines = ctx || 3
      end
      o.on(
        "-u", "-U", "--unified [LINES]", Integer,
        "Displays a unified diff with LINES lines", "of context. Default 3 lines."
      ) do |ctx|
        @format = :unified
        @lines = ctx || 3
      end
      o.on("-e", "Creates an 'ed' script to change", "oldfile to newfile.") do |_ctx|
        @format = :ed
      end
      o.on("-f", "Creates an 'ed' script to change", "oldfile to newfile in reverse order.") do |_ctx|
        @format = :reverse_ed
      end
      o.on(
        "-a", "--text",
        "Treat the files as text and compare them", "line-by-line, even if they do not seem", "to be text."
      ) do |_txt|
        @binary = false
      end
      o.on("--binary", "Treats the files as binary.") do |_bin|
        @binary = true
      end
      o.on("-q", "--brief", "Report only whether or not the files", "differ, not the details.") do |_ctx|
        @format = :report
      end
      o.on_tail("--help", "Shows this text.") do
        error << o
        return 0
      end
      o.on_tail("--version", "Shows the version of Diff::LCS.") do
        error << Diff::LCS::Ldiff::BANNER
        return 0
      end
      o.on_tail ""
      o.on_tail 'By default, runs produces an "old-style" diff, with output like UNIX diff.'
      o.parse!
    end

    unless args.size == 2
      error << args.options
      return 127
    end

    # Defaults are for old-style diff
    @format ||= :old
    @lines ||= 0

    file_old, file_new = *ARGV

    case @format
    when :context
      char_old = "*" * 3
      char_new = "-" * 3
    when :unified
      char_old = "-" * 3
      char_new = "+" * 3
    end

    # After we've read up to a certain point in each file, the number of
    # items we've read from each file will differ by FLD (could be 0).
    file_length_difference = 0

    data_old = File.read(file_old)
    data_new = File.read(file_new)

    # Test binary status
    if @binary.nil?
      old_txt = data_old[0, 4096].scan(/\0/).empty?
      new_txt = data_new[0, 4096].scan(/\0/).empty?
      @binary = !old_txt || !new_txt
    end

    unless @binary
      data_old = data_old.lines.to_a
      data_new = data_new.lines.to_a
    end

    # diff yields lots of pieces, each of which is basically a Block object
    if @binary
      diffs = (data_old == data_new)
    else
      diffs = Diff::LCS.diff(data_old, data_new)
      diffs = nil if diffs.empty?
    end

    return 0 unless diffs

    if @format == :report
      output << "Files #{file_old} and #{file_new} differ\n"
      return 1
    end

    if (@format == :unified) || (@format == :context)
      ft = File.stat(file_old).mtime.localtime.strftime("%Y-%m-%d %H:%M:%S.000000000 %z")
      output << "#{char_old} #{file_old}\t#{ft}\n"
      ft = File.stat(file_new).mtime.localtime.strftime("%Y-%m-%d %H:%M:%S.000000000 %z")
      output << "#{char_new} #{file_new}\t#{ft}\n"
    end

    # Loop over hunks. If a hunk overlaps with the last hunk, join them.
    # Otherwise, print out the old one.
    oldhunk = hunk = nil

    if @format == :ed
      real_output = output
      output = []
    end

    diffs.each do |piece|
      begin # rubocop:disable Style/RedundantBegin
        hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, @lines, file_length_difference)
        file_length_difference = hunk.file_length_difference

        next unless oldhunk
        next if @lines.positive? && hunk.merge(oldhunk)

        output << oldhunk.diff(@format)
        output << "\n" if @format == :unified
      ensure
        oldhunk = hunk
      end
    end

    last = oldhunk.diff(@format, true)
    last << "\n" if last.respond_to?(:end_with?) && !last.end_with?("\n")

    output << last

    output.reverse_each { |e| real_output << e.diff(:ed_finish) } if @format == :ed

    1
  end
end
