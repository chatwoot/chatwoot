# frozen_string_literal: true

class Pry
  class BasicObject < BasicObject
    %i[Kernel File Dir LoadError ENV Pry].each do |constant|
      const_set constant, ::Object.const_get(constant)
    end
    include Kernel
  end
end
