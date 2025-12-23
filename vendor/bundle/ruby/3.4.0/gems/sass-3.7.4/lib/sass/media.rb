# A namespace for the `@media` query parse tree.
module Sass::Media
  # A comma-separated list of queries.
  #
  #     media_query [ ',' S* media_query ]*
  class QueryList
    # The queries contained in this list.
    #
    # @return [Array<Query>]
    attr_accessor :queries

    # @param queries [Array<Query>] See \{#queries}
    def initialize(queries)
      @queries = queries
    end

    # Merges this query list with another. The returned query list
    # queries for the intersection between the two inputs.
    #
    # Both query lists should be resolved.
    #
    # @param other [QueryList]
    # @return [QueryList?] The merged list, or nil if there is no intersection.
    def merge(other)
      new_queries = queries.map {|q1| other.queries.map {|q2| q1.merge(q2)}}.flatten.compact
      return if new_queries.empty?
      QueryList.new(new_queries)
    end

    # Returns the CSS for the media query list.
    #
    # @return [String]
    def to_css
      queries.map {|q| q.to_css}.join(', ')
    end

    # Returns the Sass/SCSS code for the media query list.
    #
    # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize}).
    # @return [String]
    def to_src(options)
      queries.map {|q| q.to_src(options)}.join(', ')
    end

    # Returns a representation of the query as an array of strings and
    # potentially {Sass::Script::Tree::Node}s (if there's interpolation in it).
    # When the interpolation is resolved and the strings are joined together,
    # this will be the string representation of this query.
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    def to_a
      Sass::Util.intersperse(queries.map {|q| q.to_a}, ', ').flatten
    end

    # Returns a deep copy of this query list and all its children.
    #
    # @return [QueryList]
    def deep_copy
      QueryList.new(queries.map {|q| q.deep_copy})
    end
  end

  # A single media query.
  #
  #     [ [ONLY | NOT]? S* media_type S* | expression ] [ AND S* expression ]*
  class Query
    # The modifier for the query.
    #
    # When parsed as Sass code, this contains strings and SassScript nodes. When
    # parsed as CSS, it contains a single string (accessible via
    # \{#resolved_modifier}).
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    attr_accessor :modifier

    # The type of the query (e.g. `"screen"` or `"print"`).
    #
    # When parsed as Sass code, this contains strings and SassScript nodes. When
    # parsed as CSS, it contains a single string (accessible via
    # \{#resolved_type}).
    #
    # @return [Array<String, Sass::Script::Tree::Node>]
    attr_accessor :type

    # The trailing expressions in the query.
    #
    # When parsed as Sass code, each expression contains strings and SassScript
    # nodes. When parsed as CSS, each one contains a single string.
    #
    # @return [Array<Array<String, Sass::Script::Tree::Node>>]
    attr_accessor :expressions

    # @param modifier [Array<String, Sass::Script::Tree::Node>] See \{#modifier}
    # @param type [Array<String, Sass::Script::Tree::Node>] See \{#type}
    # @param expressions [Array<Array<String, Sass::Script::Tree::Node>>] See \{#expressions}
    def initialize(modifier, type, expressions)
      @modifier = modifier
      @type = type
      @expressions = expressions
    end

    # See \{#modifier}.
    # @return [String]
    def resolved_modifier
      # modifier should contain only a single string
      modifier.first || ''
    end

    # See \{#type}.
    # @return [String]
    def resolved_type
      # type should contain only a single string
      type.first || ''
    end

    # Merges this query with another. The returned query queries for
    # the intersection between the two inputs.
    #
    # Both queries should be resolved.
    #
    # @param other [Query]
    # @return [Query?] The merged query, or nil if there is no intersection.
    def merge(other)
      m1, t1 = resolved_modifier.downcase, resolved_type.downcase
      m2, t2 = other.resolved_modifier.downcase, other.resolved_type.downcase
      t1 = t2 if t1.empty?
      t2 = t1 if t2.empty?
      if (m1 == 'not') ^ (m2 == 'not')
        return if t1 == t2
        type = m1 == 'not' ? t2 : t1
        mod = m1 == 'not' ? m2 : m1
      elsif m1 == 'not' && m2 == 'not'
        # CSS has no way of representing "neither screen nor print"
        return unless t1 == t2
        type = t1
        mod = 'not'
      elsif t1 != t2
        return
      else # t1 == t2, neither m1 nor m2 are "not"
        type = t1
        mod = m1.empty? ? m2 : m1
      end
      Query.new([mod], [type], other.expressions + expressions)
    end

    # Returns the CSS for the media query.
    #
    # @return [String]
    def to_css
      css = ''
      css << resolved_modifier
      css << ' ' unless resolved_modifier.empty?
      css << resolved_type
      css << ' and ' unless resolved_type.empty? || expressions.empty?
      css << expressions.map do |e|
        # It's possible for there to be script nodes in Expressions even when
        # we're converting to CSS in the case where we parsed the document as
        # CSS originally (as in css_test.rb).
        e.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.to_sass : c.to_s}.join
      end.join(' and ')
      css
    end

    # Returns the Sass/SCSS code for the media query.
    #
    # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize}).
    # @return [String]
    def to_src(options)
      src = ''
      src << Sass::Media._interp_to_src(modifier, options)
      src << ' ' unless modifier.empty?
      src << Sass::Media._interp_to_src(type, options)
      src << ' and ' unless type.empty? || expressions.empty?
      src << expressions.map do |e|
        Sass::Media._interp_to_src(e, options)
      end.join(' and ')
      src
    end

    # @see \{MediaQuery#to\_a}
    def to_a
      res = []
      res += modifier
      res << ' ' unless modifier.empty?
      res += type
      res << ' and ' unless type.empty? || expressions.empty?
      res += Sass::Util.intersperse(expressions, ' and ').flatten
      res
    end

    # Returns a deep copy of this query and all its children.
    #
    # @return [Query]
    def deep_copy
      Query.new(
        modifier.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c},
        type.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c},
        expressions.map {|e| e.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}})
    end
  end

  # Converts an interpolation array to source.
  #
  # @param interp [Array<String, Sass::Script::Tree::Node>] The interpolation array to convert.
  # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize}).
  # @return [String]
  def self._interp_to_src(interp, options)
    interp.map {|r| r.is_a?(String) ? r : r.to_sass(options)}.join
  end
end
