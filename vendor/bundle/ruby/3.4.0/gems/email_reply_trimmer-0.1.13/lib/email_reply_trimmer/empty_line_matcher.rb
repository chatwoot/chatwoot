class EmptyLineMatcher

  def self.match?(line)
    line =~ /^[[:blank:]]*$/
  end

end
