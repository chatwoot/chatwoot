module AttrExtras::Utils
  def self.flat_names(names)
    names
      .flatten
      .flat_map { |x| x.is_a?(Hash) ? x.keys : x }
      .map { |x| x.to_s.sub(/!\z/, "") }
  end
end
