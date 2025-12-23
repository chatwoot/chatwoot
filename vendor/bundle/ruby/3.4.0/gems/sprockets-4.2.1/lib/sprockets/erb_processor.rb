# frozen_string_literal: true
require 'erb'

class Sprockets::ERBProcessor
  # Public: Return singleton instance with default options.
  #
  # Returns ERBProcessor object.
  def self.instance
    @instance ||= new
  end

  def self.call(input)
    instance.call(input)
  end

  def initialize(&block)
    @block = block
  end

  def call(input)
    if keyword_constructor? # Ruby 2.6+
      engine = ::ERB.new(input[:data], trim_mode: '<>')
    else
      engine = ::ERB.new(input[:data], nil, '<>')
    end
    engine.filename = input[:filename]

    context = input[:environment].context_class.new(input)
    klass = (class << context; self; end)
    klass.const_set(:ENV, context.env_proxy)
    klass.class_eval(&@block) if @block

    data = engine.result(context.instance_eval('binding'))
    context.metadata.merge(data: data)
  end

  private

  def keyword_constructor?
    return @keyword_constructor if defined? @keyword_constructor
    @keyword_constructor = ::ERB.instance_method(:initialize).parameters.include?([:key, :trim_mode])
  end
end
