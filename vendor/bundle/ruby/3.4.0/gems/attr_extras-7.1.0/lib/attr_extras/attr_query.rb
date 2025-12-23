module AttrExtras::AttrQuery
  def self.define_with_suffix(klass, suffix, *names)
    names.each do |name|
      name = name.to_s

      raise ArgumentError, "#{__method__} wants `#{name}?`, not `#{name}`." unless name.end_with?("?")

      klass.send(:define_method, name) do  # def foo?
        !!send("#{name.chop}#{suffix}")    #   !!send("foo_id")
      end                                  # end
    end
  end
end
