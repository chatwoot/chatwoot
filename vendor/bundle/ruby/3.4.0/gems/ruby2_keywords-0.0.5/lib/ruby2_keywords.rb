class Module
  unless private_method_defined?(:ruby2_keywords)
    private
    # call-seq:
    #    ruby2_keywords(method_name, ...)
    #
    # Does nothing.
    def ruby2_keywords(name, *)
      # nil
    end
  end
end

main = TOPLEVEL_BINDING.eval('self')
unless main.respond_to?(:ruby2_keywords, true)
  # call-seq:
  #    ruby2_keywords(method_name, ...)
  #
  # Does nothing.
  def main.ruby2_keywords(name, *)
    # nil
  end
end

class Proc
  unless method_defined?(:ruby2_keywords)
    # call-seq:
    #    proc.ruby2_keywords -> proc
    #
    # Does nothing and just returns the receiver.
    def ruby2_keywords
      self
    end
  end
end

class << Hash
  unless method_defined?(:ruby2_keywords_hash?)
    # call-seq:
    #    Hash.ruby2_keywords_hash?(hash) -> false
    #
    # Returns false.
    def ruby2_keywords_hash?(hash)
      false
    end
  end

  unless method_defined?(:ruby2_keywords_hash)
    # call-seq:
    #    Hash.ruby2_keywords_hash(hash) -> new_hash
    #
    # Duplicates a given hash and returns the new hash.
    def ruby2_keywords_hash(hash)
      hash.dup
    end
  end
end
