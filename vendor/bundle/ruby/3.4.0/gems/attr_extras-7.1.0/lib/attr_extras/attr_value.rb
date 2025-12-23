class AttrExtras::AttrValue
  def initialize(klass, *names)
    @klass = klass
    @names = names
  end

  attr_reader :klass, :names
  private :klass, :names

  def apply
    define_readers
    define_equals
    define_hash_identity
  end

  private

  def define_readers
    klass.send(:attr_reader, *names)
  end

  def define_equals
    names = @names  # Make available within block.

    klass.send(:define_method, :==) do |other|
      return false unless other.is_a?(self.class)

      names.all? { |attr| self.public_send(attr) == other.public_send(attr) }
    end
  end

  def define_hash_identity
    names = @names  # Make available within block.

    # Both #eql? and #hash are required for hash identity.

    klass.send(:alias_method, :eql?, :==)

    klass.send(:define_method, :hash) do
      [ self.class, *names.map { |attr| public_send(attr) } ].hash
    end
  end
end
