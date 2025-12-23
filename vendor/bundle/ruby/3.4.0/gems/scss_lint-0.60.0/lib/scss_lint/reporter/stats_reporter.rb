module SCSSLint
  # Reports a single line per lint.
  class Reporter::StatsReporter < Reporter
    def report_lints # rubocop:disable Metrics/AbcSize
      return unless lints.any?

      stats = organize_stats
      total_lints = lints.length
      linter_name_length =
        stats.inject('') { |memo, stat| memo.length > stat[0].length ? memo : stat[0] }.length
      total_files = lints.group_by(&:filename).size

      # Math.log10(1) is 0; avoid this by using at least 1.
      lint_count_length = [1, Math.log10(total_lints).ceil].max
      file_count_length = [1, Math.log10(total_files).ceil].max

      str = ''
      stats.each do |linter_name, lint_count, file_count|
        str << "%#{lint_count_length}d  %-#{linter_name_length}s" % [lint_count, linter_name]
        str << "        (across %#{file_count_length}d files)\n" % [file_count]
      end
      str << "#{'-' * lint_count_length}  #{'-' * linter_name_length}"
      str << "        #{'-' * (file_count_length + 15)}\n"
      str << "%#{lint_count_length}d  #{'total'.ljust(linter_name_length)}" % total_lints
      str << "        (across %#{file_count_length}d files)\n" % total_files
      str
    end

    def organize_stats
      lints
        .group_by(&:linter)
        .sort_by { |_, lints_by_linter| -lints_by_linter.size }
        .inject([]) do |ary, (linter, lints_by_linter)|
          file_count = lints_by_linter.group_by(&:filename).size
          ary << [linter.name, lints_by_linter.size, file_count]
        end
    end
  end
end
