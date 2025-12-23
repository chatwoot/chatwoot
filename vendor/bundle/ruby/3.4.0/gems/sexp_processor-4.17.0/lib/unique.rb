##
# Unique creates unique variable names.

class Unique
  ##
  # Reset current count back to zero. Mainly used for testing.

  def self.reset
    @@curr = 0
  end

  ##
  # Get the next unique variable name.

  def self.next
    @@curr += 1
    "temp_#{@@curr}".intern
  end

  reset
end
