class Reline::KeyStroke
  ESC_BYTE = 27
  CSI_PARAMETER_BYTES_RANGE = 0x30..0x3f
  CSI_INTERMEDIATE_BYTES_RANGE = (0x20..0x2f)

  def initialize(config)
    @config = config
  end

  def compress_meta_key(ary)
    return ary unless @config.convert_meta
    ary.inject([]) { |result, key|
      if result.size > 0 and result.last == "\e".ord
        result[result.size - 1] = Reline::Key.new(key, key | 0b10000000, true)
      else
        result << key
      end
      result
    }
  end

  def start_with?(me, other)
    compressed_me = compress_meta_key(me)
    compressed_other = compress_meta_key(other)
    i = 0
    loop do
      my_c = compressed_me[i]
      other_c = compressed_other[i]
      other_is_last = (i + 1) == compressed_other.size
      me_is_last = (i + 1) == compressed_me.size
      if my_c != other_c
        if other_c == "\e".ord and other_is_last and my_c.is_a?(Reline::Key) and my_c.with_meta
          return true
        else
          return false
        end
      elsif other_is_last
        return true
      elsif me_is_last
        return false
      end
      i += 1
    end
  end

  def equal?(me, other)
    case me
    when Array
      compressed_me = compress_meta_key(me)
      compressed_other = compress_meta_key(other)
      compressed_me.size == compressed_other.size and [compressed_me, compressed_other].transpose.all?{ |i| equal?(i[0], i[1]) }
    when Integer
      if other.is_a?(Reline::Key)
        if other.combined_char == "\e".ord
          false
        else
          other.combined_char == me
        end
      else
        me == other
      end
    when Reline::Key
      if other.is_a?(Integer)
        me.combined_char == other
      else
        me == other
      end
    end
  end

  def match_status(input)
    key_mapping.keys.select { |lhs|
      start_with?(lhs, input)
    }.tap { |it|
      return :matched  if it.size == 1 && equal?(it[0], input)
      return :matching if it.size == 1 && !equal?(it[0], input)
      return :matched  if it.max_by(&:size)&.size&.< input.size
      return :matching if it.size > 1
    }
    if key_mapping.keys.any? { |lhs| start_with?(input, lhs) }
      :matched
    else
      match_unknown_escape_sequence(input).first
    end
  end

  def expand(input)
    lhs = key_mapping.keys.select { |item| start_with?(input, item) }.sort_by(&:size).last
    unless lhs
      status, size = match_unknown_escape_sequence(input)
      case status
      when :matched
        return [:ed_unassigned] + expand(input.drop(size))
      when :matching
        return [:ed_unassigned]
      else
        return input
      end
    end
    rhs = key_mapping[lhs]

    case rhs
    when String
      rhs_bytes = rhs.bytes
      expand(expand(rhs_bytes) + expand(input.drop(lhs.size)))
    when Symbol
      [rhs] + expand(input.drop(lhs.size))
    when Array
      rhs
    end
  end

  private

  # returns match status of CSI/SS3 sequence and matched length
  def match_unknown_escape_sequence(input)
    idx = 0
    return [:unmatched, nil] unless input[idx] == ESC_BYTE
    idx += 1
    idx += 1 if input[idx] == ESC_BYTE

    case input[idx]
    when nil
      return [:matching, nil]
    when 91 # == '['.ord
      # CSI sequence
      idx += 1
      idx += 1 while idx < input.size && CSI_PARAMETER_BYTES_RANGE.cover?(input[idx])
      idx += 1 while idx < input.size && CSI_INTERMEDIATE_BYTES_RANGE.cover?(input[idx])
      input[idx] ? [:matched, idx + 1] : [:matching, nil]
    when 79 # == 'O'.ord
      # SS3 sequence
      input[idx + 1] ? [:matched, idx + 2] : [:matching, nil]
    else
      if idx == 1
        # `ESC char`, make it :unmatched so that it will be handled correctly in `read_2nd_character_of_key_sequence`
        [:unmatched, nil]
      else
        # `ESC ESC char`
        [:matched, idx + 1]
      end
    end
  end

  def key_mapping
    @config.key_bindings
  end
end
