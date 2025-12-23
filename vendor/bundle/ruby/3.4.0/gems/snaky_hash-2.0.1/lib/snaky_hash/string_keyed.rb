module SnakyHash
  class StringKeyed < Hashie::Mash
    include SnakyHash::Snake.new(key_type: :string)
  end
end
