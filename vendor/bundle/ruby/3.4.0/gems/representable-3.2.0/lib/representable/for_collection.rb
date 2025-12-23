module Representable
  # Gives us Representer::for_collection and its configuration directive
  # ::collection_representer.
  module ForCollection
    def for_collection
      # this is done at run-time, not a big fan of this. however, it saves us from inheritance/self problems.
      @collection_representer ||= collection_representer!({}) # DON'T make it inheritable as it would inherit the wrong singular.
    end

  private
    def collection_representer!(options)
      singular = self

      # what happens here is basically
      # Module.new { include Representable::JSON::Collection; ... }
      nested_builder.(
        _base:     default_nested_class,
        _features: [singular.collection_representer_class],
        _block:    ->(*) { items options.merge(:extend => singular) }
      )
    end

    def collection_representer(options={})
      @collection_representer = collection_representer!(options)
    end
  end
end
