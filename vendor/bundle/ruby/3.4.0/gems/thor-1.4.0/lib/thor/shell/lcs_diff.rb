module LCSDiff
protected

  # Overwrite show_diff to show diff with colors if Diff::LCS is
  # available.
  def show_diff(destination, content) #:nodoc:
    if diff_lcs_loaded? && ENV["THOR_DIFF"].nil? && ENV["RAILS_DIFF"].nil?
      actual  = File.binread(destination).to_s.split("\n")
      content = content.to_s.split("\n")

      Diff::LCS.sdiff(actual, content).each do |diff|
        output_diff_line(diff)
      end
    else
      super
    end
  end

private

  def output_diff_line(diff) #:nodoc:
    case diff.action
    when "-"
      say "- #{diff.old_element.chomp}", :red, true
    when "+"
      say "+ #{diff.new_element.chomp}", :green, true
    when "!"
      say "- #{diff.old_element.chomp}", :red, true
      say "+ #{diff.new_element.chomp}", :green, true
    else
      say "  #{diff.old_element.chomp}", nil, true
    end
  end

  # Check if Diff::LCS is loaded. If it is, use it to create pretty output
  # for diff.
  def diff_lcs_loaded? #:nodoc:
    return true if defined?(Diff::LCS)
    return @diff_lcs_loaded unless @diff_lcs_loaded.nil?

    @diff_lcs_loaded = begin
      require "diff/lcs"
      true
    rescue LoadError
      false
    end
  end

end
