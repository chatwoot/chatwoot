class Events::Base
  attr_accessor :data
  attr_reader :name, :timestamp

  def initialize(name, timestamp, data)
    @name = name
    @data = data
    @timestamp = timestamp
  end

  def method_name
    name.to_s.tr('.', '_')
  end
end
