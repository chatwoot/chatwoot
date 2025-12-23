# frozen_string_literal: true
require 'set'

module Sprockets
  # Internal: Utils, we didn't know where else to put it! Functions may
  # eventually be shuffled into more specific drawers.
  module Utils
    extend self

    # Internal: Check if object can safely be .dup'd.
    #
    # Similar to ActiveSupport #duplicable? check.
    #
    # obj - Any Object
    #
    # Returns false if .dup would raise a TypeError, otherwise true.
    def duplicable?(obj)
      case obj
      when NilClass, FalseClass, TrueClass, Symbol, Numeric
        false
      else
        true
      end
    end

    # Internal: Duplicate and store key/value on new frozen hash.
    #
    # Separated for recursive calls, always use hash_reassoc(hash, *keys).
    #
    # hash - Hash
    # key  - Object key
    #
    # Returns Hash.
    def hash_reassoc1(hash, key)
      hash = hash.dup if hash.frozen?
      old_value = hash[key]
      old_value = old_value.dup if duplicable?(old_value)
      new_value = yield old_value
      new_value.freeze if duplicable?(new_value)
      hash.store(key, new_value)
      hash.freeze
    end

    # Internal: Duplicate and store key/value on new frozen hash.
    #
    # Similar to Hash#store for nested frozen hashes.
    #
    # hash  - Hash
    # key_a - Object key. Use multiple keys for nested hashes.
    # key_b - Object key. Use multiple keys for nested hashes.
    # block - Receives current value at key.
    #
    # Examples
    #
    #     config = {paths: ["/bin", "/sbin"]}.freeze
    #     new_config = hash_reassoc(config, :paths) do |paths|
    #       paths << "/usr/local/bin"
    #     end
    #
    # Returns duplicated frozen Hash.
    def hash_reassoc(hash, key_a, key_b = nil, &block)
      if key_b
        hash_reassoc1(hash, key_a) do |value|
          hash_reassoc(value, key_b, &block)
        end
      else
        hash_reassoc1(hash, key_a, &block)
      end
    end

    WHITESPACE_ORDINALS = {0x0A => "\n", 0x20 => " ", 0x09 => "\t"}
    private_constant :WHITESPACE_ORDINALS

    # Internal: Check if string has a trailing semicolon.
    #
    # str - String
    #
    # Returns true or false.
    def string_end_with_semicolon?(str)
      i = str.size - 1
      while i >= 0
        c = str[i].ord
        i -= 1

        next if WHITESPACE_ORDINALS[c]

        return c === 0x3B
      end

      true
    end

    # Internal: Accumulate asset source to buffer and append a trailing
    # semicolon if necessary.
    #
    # buf    - String buffer to append to
    # source - String source to append
    #
    # Returns buf String.
    def concat_javascript_sources(buf, source)
      return buf if source.bytesize <= 0

      buf << source
      # If the source contains non-ASCII characters, indexing on it becomes O(N).
      # This will lead to O(N^2) performance in string_end_with_semicolon?, so we should use 32 bit encoding to make sure indexing stays O(1)
      source = source.encode(Encoding::UTF_32LE) unless source.ascii_only?
      return buf if string_end_with_semicolon?(source)

      # If the last character in the string was whitespace,
      # such as a newline, then we want to put the semicolon
      # before the whitespace. Otherwise append a semicolon.
      if whitespace = WHITESPACE_ORDINALS[source[-1].ord]
        buf[-1] = ";#{whitespace}"
      else
        buf << ";"
      end

      buf
    end

    MODULE_INCLUDE_MUTEX = Mutex.new
    private_constant :MODULE_INCLUDE_MUTEX

    # Internal: Inject into target module for the duration of the block.
    #
    # mod - Module
    #
    # Returns result of block.
    def module_include(base, mod)
      MODULE_INCLUDE_MUTEX.synchronize do
        old_methods = {}

        mod.instance_methods.each do |sym|
          old_methods[sym] = base.instance_method(sym) if base.method_defined?(sym)
        end

        mod.instance_methods.each do |sym|
          method = mod.instance_method(sym)
          if base.method_defined?(sym)
            base.send(:alias_method, sym, sym)
          end
          base.send(:define_method, sym, method)
        end

        yield
      ensure
        mod.instance_methods.each do |sym|
          base.send(:undef_method, sym) if base.method_defined?(sym)
        end
        old_methods.each do |sym, method|
          base.send(:define_method, sym, method)
        end
      end
    end

    # Internal: Post-order Depth-First search algorithm.
    #
    # Used for resolving asset dependencies.
    #
    # initial - Initial Array of nodes to traverse.
    # block   -
    #   node  - Current node to get children of
    #
    # Returns a Set of nodes.
    def dfs(initial)
      nodes, seen = Set.new, Set.new
      stack = Array(initial).reverse

      while node = stack.pop
        if seen.include?(node)
          nodes.add(node)
        else
          seen.add(node)
          stack.push(node)
          stack.concat(Array(yield node).reverse)
        end
      end

      nodes
    end

    # Internal: Post-order Depth-First search algorithm that gathers all paths
    # along the way.
    #
    # TODO: Rename function.
    #
    # path   - Initial Array node path
    # block  -
    #   node - Current node to get children of
    #
    # Returns an Array of node Arrays.
    def dfs_paths(path)
      paths = []
      stack = [path]
      seen  = Set.new

      while path = stack.pop
        seen.add(path.last)
        paths << path

        children = yield path.last
        children.reverse_each do |node|
          stack.push(path + [node]) unless seen.include?(node)
        end
      end

      paths
    end
  end
end
