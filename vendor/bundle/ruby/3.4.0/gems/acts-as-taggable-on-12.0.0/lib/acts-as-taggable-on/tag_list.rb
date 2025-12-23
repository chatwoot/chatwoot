# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module ActsAsTaggableOn
  class TagList < Array
    attr_accessor :owner, :parser

    def initialize(*args)
      @parser = ActsAsTaggableOn.default_parser
      add(*args)
    end

    ##
    # Add tags to the tag_list. Duplicate or blank tags will be ignored.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.add("Fun", "Happy")
    #   tag_list.add("Fun, Happy", :parse => true)
    def add(*names)
      extract_and_apply_options!(names)
      concat(names)
      clean!
      self
    end

    # Append---Add the tag to the tag_list. This
    # expression returns the tag_list itself, so several appends
    # may be chained together.
    def <<(obj)
      add(obj)
    end

    # Concatenation --- Returns a new tag list built by concatenating the
    # two tag lists together to produce a third tag list.
    def +(other)
      TagList.new.add(self).add(other)
    end

    # Appends the elements of +other_tag_list+ to +self+.
    def concat(other_tag_list)
      super(other_tag_list).send(:clean!)
      self
    end

    ##
    # Remove specific tags from the tag_list.
    # Use the <tt>:parse</tt> option to add an unparsed tag string.
    #
    # Example:
    #   tag_list.remove("Sad", "Lonely")
    #   tag_list.remove("Sad, Lonely", :parse => true)
    def remove(*names)
      extract_and_apply_options!(names)
      delete_if { |name| names.include?(name) }
      self
    end

    ##
    # Transform the tag_list into a tag string suitable for editing in a form.
    # The tags are joined with <tt>TagList.delimiter</tt> and quoted if necessary.
    #
    # Example:
    #   tag_list = TagList.new("Round", "Square,Cube")
    #   tag_list.to_s # 'Round, "Square,Cube"'
    def to_s
      tags = frozen? ? dup : self
      tags.send(:clean!)

      tags.map do |name|
        d = ActsAsTaggableOn.delimiter
        d = Regexp.new d.join('|') if d.is_a? Array
        name.index(d) ? "\"#{name}\"" : name
      end.join(ActsAsTaggableOn.glue)
    end

    private

    # Convert everything to string, remove whitespace, duplicates, and blanks.
    def clean!
      reject!(&:blank?)
      map!(&:to_s)
      map!(&:strip)
      map! { |tag| tag.mb_chars.downcase.to_s } if ActsAsTaggableOn.force_lowercase
      map!(&:parameterize) if ActsAsTaggableOn.force_parameterize

      ActsAsTaggableOn.strict_case_match ? uniq! : uniq!(&:downcase)
      self
    end

    def extract_and_apply_options!(args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.assert_valid_keys :parse, :parser

      parser = options[:parser] || @parser

      args.map! { |a| parser.new(a).parse } if options[:parse] || options[:parser]

      args.flatten!
    end
  end
end
