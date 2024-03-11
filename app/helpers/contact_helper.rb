module ContactHelper
  def parse_name(full_name)
    #  If the input is nil or not a string, return a hash with all values set to nil
    return default_name_hash if invalid_name?(full_name)

    # If the input is a number, return a hash with the number as the first name
    return numeric_name_hash(full_name) if valid_number?(full_name)

    full_name = full_name.squish

    # If full name consists of only one word, consider it as the first name
    return single_word_name_hash(full_name) if single_word?(full_name)

    parts = split_name(full_name)
    parts = handle_conjunction(parts)
    build_name_hash(parts)
  end

  private

  def default_name_hash
    { first_name: nil, last_name: nil, middle_name: nil, prefix: nil, suffix: nil }
  end

  def invalid_name?(full_name)
    !full_name.is_a?(String) || full_name.empty?
  end

  def numeric_name_hash(full_name)
    { first_name: full_name, last_name: nil, middle_name: nil, prefix: nil, suffix: nil }
  end

  def valid_number?(full_name)
    full_name.gsub(/\s+/, '').match?(/\A\+?\d+\z/)
  end

  def single_word_name_hash(full_name)
    { first_name: full_name, last_name: nil, middle_name: nil, prefix: nil, suffix: nil }
  end

  def single_word?(full_name)
    full_name.split.size == 1
  end

  def split_name(full_name)
    full_name.split
  end

  def handle_conjunction(parts)
    conjunctions = ['and', '&']
    parts.each_index do |i|
      next unless conjunctions.include?(parts[i]) && i.positive?

      parts[i - 1] = [parts[i - 1], parts[i + 1]].join(' ')
      parts.delete_at(i)
      parts.delete_at(i)
    end
    parts
  end

  def build_name_hash(parts)
    suffix = parts.pop if parts.last.match?(/(\w+\.|[IVXLM]+|[A-Z]+)$/)
    last_name = parts.pop
    prefix = parts.shift if parts.first.match?(/^\w+\./)
    first_name = parts.shift
    middle_name = parts.join(' ')

    hash = {
      first_name: first_name,
      last_name: last_name,
      prefix: prefix,
      middle_name: middle_name,
      suffix: suffix
    }

    # Reverse name if "," was used in Last, First notation.
    if hash[:first_name] =~ /,$/
      hash[:first_name] = hash[:last_name]
      hash[:last_name] = Regexp.last_match.pre_match
    end
    hash
  end
end
