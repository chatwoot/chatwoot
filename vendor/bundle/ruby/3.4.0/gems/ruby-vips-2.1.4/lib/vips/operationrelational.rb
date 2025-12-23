module Vips
  # The type of relational operation to perform on an image. See
  # {Image#relational}.
  #
  # * ':more' more than
  # * ':less' less than
  # * ':moreeq' more than or equal to
  # * ':lesseq' less than or equal to
  # * ':equal' equal to
  # * ':noteq' not equal to

  class OperationRelational < Symbol
  end
end
