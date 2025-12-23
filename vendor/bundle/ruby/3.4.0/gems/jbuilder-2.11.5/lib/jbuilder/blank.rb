class Jbuilder
  class Blank
    def ==(other)
      super || Blank === other
    end

    def empty?
      true
    end
  end
end
