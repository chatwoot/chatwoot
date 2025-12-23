# frozen_string_literal: true

module Hashdiff
  # @private
  #
  # judge whether two objects are similar
  def self.similar?(obja, objb, options = {})
    return compare_values(obja, objb, options) if !options[:comparison] && !any_hash_or_array?(obja, objb)

    count_a = count_nodes(obja)
    count_b = count_nodes(objb)

    return true if (count_a + count_b).zero?

    opts = { similarity: 0.8 }.merge!(options)

    diffs = count_diff diff(obja, objb, opts)

    (1 - diffs / (count_a + count_b).to_f) >= opts[:similarity]
  end

  # @private
  #
  # count node differences
  def self.count_diff(diffs)
    diffs.inject(0) do |sum, item|
      old_change_count = count_nodes(item[2])
      new_change_count = count_nodes(item[3])
      sum + (old_change_count + new_change_count)
    end
  end

  # @private
  #
  # count total nodes for an object
  def self.count_nodes(obj)
    return 0 unless obj

    count = 0
    if obj.is_a?(Array)
      obj.each { |e| count += count_nodes(e) }
    elsif obj.is_a?(Hash)
      obj.each_value { |v| count += count_nodes(v) }
    else
      return 1
    end

    count
  end

  # @private
  #
  # decode property path into an array
  # @param [String] path Property-string
  # @param [String] delimiter Property-string delimiter
  #
  # e.g. "a.b[3].c" => ['a', 'b', 3, 'c']
  def self.decode_property_path(path, delimiter = '.')
    path.split(delimiter).inject([]) do |memo, part|
      if part =~ /^(.*)\[(\d+)\]$/
        if !Regexp.last_match(1).empty?
          memo + [Regexp.last_match(1), Regexp.last_match(2).to_i]
        else
          memo + [Regexp.last_match(2).to_i]
        end
      else
        memo + [part]
      end
    end
  end

  # @private
  #
  # get the node of hash by given path parts
  def self.node(hash, parts)
    temp = hash
    parts.each do |part|
      temp = temp[part]
    end
    temp
  end

  # @private
  #
  # check for equality or "closeness" within given tolerance
  def self.compare_values(obj1, obj2, options = {})
    if options[:numeric_tolerance].is_a?(Numeric) &&
       obj1.is_a?(Numeric) && obj2.is_a?(Numeric)
      return (obj1 - obj2).abs <= options[:numeric_tolerance]
    end

    if options[:strip] == true
      obj1 = obj1.strip if obj1.respond_to?(:strip)
      obj2 = obj2.strip if obj2.respond_to?(:strip)
    end

    if options[:case_insensitive] == true
      obj1 = obj1.downcase if obj1.respond_to?(:downcase)
      obj2 = obj2.downcase if obj2.respond_to?(:downcase)
    end

    obj1 == obj2
  end

  # @private
  #
  # check if objects are comparable
  def self.comparable?(obj1, obj2, strict = true)
    return true if (obj1.is_a?(Array) || obj1.is_a?(Hash)) && obj2.is_a?(obj1.class)
    return true if (obj2.is_a?(Array) || obj2.is_a?(Hash)) && obj1.is_a?(obj2.class)
    return true if !strict && obj1.is_a?(Numeric) && obj2.is_a?(Numeric)

    obj1.is_a?(obj2.class) && obj2.is_a?(obj1.class)
  end

  # @private
  #
  # try custom comparison
  def self.custom_compare(method, key, obj1, obj2)
    return unless method

    res = method.call(key, obj1, obj2)

    # nil != false here
    return [['~', key, obj1, obj2]] if res == false
    return [] if res == true
  end

  def self.prefix_append_key(prefix, key, opts)
    if opts[:array_path]
      prefix + [key]
    else
      prefix.empty? ? key.to_s : "#{prefix}#{opts[:delimiter]}#{key}"
    end
  end

  def self.prefix_append_array_index(prefix, array_index, opts)
    if opts[:array_path]
      prefix + [array_index]
    else
      "#{prefix}[#{array_index}]"
    end
  end

  class << self
    private

    # @private
    #
    # checks if both objects are Arrays or Hashes
    def any_hash_or_array?(obja, objb)
      obja.is_a?(Array) || obja.is_a?(Hash) || objb.is_a?(Array) || objb.is_a?(Hash)
    end
  end
end
