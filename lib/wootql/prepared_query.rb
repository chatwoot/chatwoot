class Wootql::PreparedQuery
  def initialize(&execute)
    @execute = execute
  end

  def page(offset = 0, debug: false)
    @execute.call(offset, debug)
  end
end
