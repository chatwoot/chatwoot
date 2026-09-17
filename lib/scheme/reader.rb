class Scheme::Reader
  CHARACTER_NAMES = { 'alarm' => "\a", 'backspace' => "\b", 'delete' => "\x7f", 'escape' => "\e", 'newline' => "\n",
                      'null' => "\0", 'return' => "\r", 'space' => ' ', 'tab' => "\t" }.freeze
  ABBREVIATIONS = { "'" => :quote, '`' => :quasiquote, ',' => :unquote }.freeze
  MAX_DEPTH = 512

  def initialize(source)
    @source = source
    @index = 0
    @fold_case = false
  end

  def read_all
    values = []
    skip_space
    until eof?
      values << datum(0)
      skip_space
    end
    values
  end

  private

  def datum(depth)
    fail_read('datum nesting limit exceeded') if depth > MAX_DEPTH
    skip_space(depth)
    fail_read('unexpected end of input') if eof?
    char = take
    case char
    when '(' then read_list(depth + 1)
    when ')' then fail_read('unexpected closing parenthesis', offset: @index - 1)
    when '"' then quoted('"')
    when '|' then quoted('|').to_sym
    when "'", '`', ','
      name = ABBREVIATIONS.fetch(char)
      name = :'unquote-splicing' if char == ',' && peek == '@' && take
      Scheme.list([name, datum(depth + 1)])
    when '#' then dispatch(depth)
    else atom(char + token)
    end
  end

  def dispatch(depth)
    if peek == '(' || @source[@index, 3]&.downcase == 'u8('
      bytevector = peek != '('
      @index += bytevector ? 3 : 1
      items = Scheme.to_a(read_list(depth + 1))
      return bytevector ? Scheme::Bytevector.new(items) : Scheme::Vector.new(items)
    end
    if peek == '\\'
      take
      first = take
      fail_read('missing character') unless first
      name = first + token
      value = CHARACTER_NAMES[name.downcase] || (name.length == 1 ? name : nil)
      value ||= name[1..].to_i(16).chr(Encoding::UTF_8) if name.match?(/\Ax[0-9a-f]+\z/i)
      fail_read('unknown character name') unless value
      return Scheme::Character.new(value)
    end
    atom('#' + token)
  rescue Scheme::Error, RangeError => e
    fail_read(e.message)
  end

  def read_list(depth)
    items = []
    loop do
      skip_space(depth)
      fail_read('unclosed list') if eof?
      return Scheme.list(items) if peek == ')' && take

      if peek == '.' && delimiter?(@source[@index + 1])
        take
        fail_read('dot must follow a list element') if items.empty?
        tail = datum(depth)
        skip_space(depth)
        fail_read('expected closing parenthesis after dotted tail') unless take == ')'
        return Scheme.list(items, tail)
      end
      items << datum(depth)
    end
  end

  def atom(text)
    return true if %w[#t #true].include?(text.downcase)
    return false if %w[#f #false].include?(text.downcase)

    number = Scheme::Numbers.parse(text)
    return number unless number == false

    fail_read("invalid token #{text.inspect}") if text.start_with?('#') || text == '.' || text.match?(/\A[0-9]/)
    (@fold_case ? text.downcase : text).to_sym
  end

  def quoted(ending)
    output = +''
    until eof?
      char = take
      return output if char == ending

      if char == '\\'
        escaped = take
        case escaped
        when 'x'
          hex = +''
          hex << take until eof? || peek == ';'
          fail_read('invalid hexadecimal escape') unless take == ';' && hex.match?(/\A[0-9a-f]+\z/i)
          output << hex.to_i(16).chr(Encoding::UTF_8)
        when "\n", "\r", ' ', "\t"
          take while [' ', "\t"].include?(peek)
          line_ending = ["\n", "\r"].include?(escaped) ? escaped : take
          fail_read('expected a line ending after string escape') unless ["\n", "\r"].include?(line_ending)
          take if peek == "\n" && line_ending == "\r"
          take while [' ', "\t"].include?(peek)
        else
          decoded = { 'a' => "\a", 'b' => "\b", 't' => "\t", 'n' => "\n", 'r' => "\r", '"' => '"', '\\' => '\\', '|' => '|' }[escaped]
          fail_read('invalid escape') unless decoded
          output << decoded
        end
      else
        output << char
      end
    end
    fail_read('unterminated string or symbol')
  rescue RangeError => e
    fail_read(e.message)
  end

  def skip_space(depth = 0)
    loop do
      take while peek&.match?(/\s/)
      if peek == ';'
        take until eof? || peek == "\n"
      elsif @source[@index, 2] == '#|'
        @index += 2
        nesting = 1
        while nesting.positive?
          fail_read('unterminated block comment') if eof?
          case @source[@index, 2]
          when '#|' then nesting += 1
                         @index += 2
          when '|#' then nesting -= 1
                         @index += 2
          else take
          end
        end
      elsif @source[@index, 2] == '#;'
        @index += 2
        datum(depth + 1)
      elsif @source[@index, 2] == '#!'
        directive = token
        fail_read('unknown reader directive') unless %w[#!fold-case #!no-fold-case].include?(directive)
        @fold_case = directive == '#!fold-case'
      else
        return
      end
    end
  end

  def token
    start = @index
    take until delimiter?(peek)
    @source[start...@index]
  end

  def delimiter?(char)
    char.nil? || char.match?(/[\s()";'`,|]/)
  end

  def peek
    @source[@index]
  end

  def take
    char = peek
    @index += 1 unless char.nil?
    char
  end

  def eof?
    @index >= @source.length
  end

  def fail_read(message, offset: @index)
    before = @source[0...offset]
    line = before.count("\n") + 1
    column = offset - (before.rindex("\n") || -1)
    raise Scheme::ReadError, "#{message} at line #{line}, column #{column}"
  end
end
