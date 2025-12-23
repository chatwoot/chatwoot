module SnakyHash
  class SymbolKeyed < Hashie::Mash
    include SnakyHash::Snake.new(key_type: :symbol)
  end
end
