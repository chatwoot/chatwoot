require_relative "../../retriable"

module Kernel
  def retriable(opts = {}, &block)
    Retriable.retriable(opts, &block)
  end

  def retriable_with_context(context_key, opts = {}, &block)
    Retriable.with_context(context_key, opts, &block)
  end
end
