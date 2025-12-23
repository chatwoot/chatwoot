class Regexp
  TOKEN_KEYS = %i[
    type
    token
    text
    ts
    te
    level
    set_level
    conditional_level
  ].freeze

  Token = Struct.new(*TOKEN_KEYS) do
    attr_accessor :previous, :next

    def offset
      [ts, te]
    end

    def length
      te - ts
    end
  end
end
