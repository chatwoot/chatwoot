class BaseDispatcher
  include Wisper::Publisher

  def listeners
    []
  end

  def load_listeners
    listeners.each { |listener| subscribe(listener) }
  end
end
