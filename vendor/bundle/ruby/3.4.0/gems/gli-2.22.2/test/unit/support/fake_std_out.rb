class FakeStdOut
  attr_reader :strings

  def initialize
    @strings = []
  end

  def puts(string=nil)
    @strings << string unless string.nil?
  end

  def write(x)
    puts(x)
  end

  def printf(*args)
    puts(Kernel.printf(*args))
  end

  # Returns true if the regexp matches anything in the output
  def contained?(regexp)
    strings.find{ |x| x =~ regexp }
  end

  def flush; end

  def to_s
    @strings.join("\n")
  end
end
