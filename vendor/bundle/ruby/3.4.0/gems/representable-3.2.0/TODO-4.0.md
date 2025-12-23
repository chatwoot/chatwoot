# Decorator

  XML::Binding::Collection.to_xml(represented)
    bindings.each bin.to_xml


  # hat vorteil: [].each{ Collection.to_xml(item) }

* make all properties "Object-like", even arrays of strings etc. This saves us from having `extend ObjectBinding if typed?` and we could just call to_hash/from_hash on all attributes. performance issues here? otherwise: implement!


# how to?

class CH
  wrap :character
  prpoerty :a


class
  proerty :author, dec: CH

# how to?

* override specific bindings and their logic? e.g. `Namespace#read`
* Extend nested representers, e.g. the namespace prefix, when it gets plugged into composition
* Easier polymorphic representer

# XML

* ditch annoying nokogiri in favor of https://github.com/YorickPeterse/oga

# Parsing

* Let bindings have any "xpath"
* Allow to parse "wildcard" sections where you have no idea about the property names (and attribute names, eg. with links)

# Options

* There should be an easier way to pass a set of options to all nested #to_node decorators.

```ruby
representable_attrs.keys.each do |property|
  options[property.to_sym] = { show_definition: false, namespaces: options[:namespaces] }
end
```

* Allow passing options to Binding#serialize.
  serialize(.., options{:exclude => ..})


# wrap, as

AsWithNamespace( Binding )
   BUT NOT FOR AsWithNamespace( Binding::Attribute )
  => selectively wrap bindings at compile- and runtime






* Cleanup the manifest part in Decorator.

* all property objects should be extended/wrapped so we don't need the switch.

# Deprecations

* deprecate instance: { nil } which is superseded by parse_strategy: :sync



from_hash, property :band, class: vergessen
