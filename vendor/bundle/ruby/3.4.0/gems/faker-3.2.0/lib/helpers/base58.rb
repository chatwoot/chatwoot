# frozen_string_literal: true

module Faker
  module Base58
    def self.encode(str)
      alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
      base = alphabet.size

      lv = 0
      str.chars.reverse.each_with_index { |v, i| lv += v.unpack1('C') * 256**i }

      ret = +''
      while lv.positive?
        lv, mod = lv.divmod(base)
        ret << alphabet[mod]
      end

      npad = str.match(/^#{0.chr}*/)[0].to_s.size
      '1' * npad + ret.reverse
    end
  end
end
