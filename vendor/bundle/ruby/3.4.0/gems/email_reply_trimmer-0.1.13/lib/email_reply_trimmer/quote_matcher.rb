class QuoteMatcher

  def self.match?(line)
    line =~ /^[[:blank:]]*>/
  end

end
