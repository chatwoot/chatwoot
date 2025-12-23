# 3.2.0
* Drop support for Virtus Coercion
* Fix deprecation warning with Nokogiri 1.13.0

# 3.1.1

* Upgrade `trailblazer-option` to `0.1.1` which supports passing an empty `keyword_arguments`.

# 3.1.0
* Remove circular require
* Use Dry-types 1.0.0+ as coercion library
* Renamed Coercion to VirtusCoercion to support old codebases
* Replace `declarative-option` with [`trailblazer-option`](https://github.com/trailblazer/trailblazer-option)

# 3.0.4

* Add proper XML namespace support.
* [internal] Replace `XML::Binding#node_for` with function `XML::Node`.

# 3.0.3

* Replace `Uber::Option` with the new [`Declarative::Option`](https://github.com/apotonick/declarative-option). This should result in a significant performance boost.

# 3.0.2

* Initialize `Config@wrap` to avoid Ruby's warning.
* Add `#render` and `#parse` alias methods to all format modules as a generic entry point.
* In `GetValue`, use `public_send` now.

# 3.0.1

* Loosen `uber` dependency.

# 3.0.0

* Removed deprecations from 2.4.
* Removed `:parse_strategy` in favor of `:populator`.
* Removed `:binding` in favor of your own pipeline.

# 2.4.1

* No need to use Uber::Callable in Pipeline as this object is always invoked via `#call`.

# 2.4.0

Full migration guide here: http://trailblazer.to/gems/representable/upgrading-guide.html#to-24

* Breaking API change: `:parse_filter` and `:render_filter` have no deprecation as all the other, they receive one options.
render_filter: val, doc, options
* `Decorator` always needs a format engine included, e.g. `Representable::JSON` to build bindings at compile-time.
* Removed `Representable::Apply`. This is now done via `Schema`.
representer_class.representable_attrs is definitions
* Removed `:use_decorator` option. Use a decorator instead.

* Added `Representable.deprecations = false` to disable slow and weird deprecation code.

* Removed `Binding#user_options`. This is now available via `->(options[:user_options])`.
* Removed `Binding#as`.
* Removed `Binding#parent_decorator`.

## Internal Changes
* Removed `Binding@represented` (which was never public anyway). Use `Binding#represented`.
* Changed signature: `Binding#get(represented:)`. In now needs a hash `{represented: ..}`.

# 2.4.0.rc5

* Fix double definition of `Insert`.
* Deprecate `:binding`.

# 2.4.0.rc4

* The preferred way of passing user options is now `to_hash(user_options: {})`.
* Supports nested options for nested representers.

# 2.4.0.rc3

* `Set` is `SetValue`. `Get` is `GetValue`.
* `CreateObject` no longer invokes `AssignFragment`. This is now part of the official parse pipeline.

# 2.4.0.rc2

* Use Declarative's `::build_definition` interface instead of overwriting `::property`.

# 2.3.0

* Remove dependency to Nokogiri and Multi_JSON. You have to add what you need to your `Gemfile`/`gemspec` now.
* `to_*`/`from_*` with options do no longer change the hash but work on copies.
* `to_*`/`from_*` now respect `wrap: false`. This will suppress the wrapping on the first level.
* Introduce `property "name", wrap: false`. This allows reusing existing representers with `representation_wrap` set as nested representers but suppressing the wrapping.

    ```ruby
    class BandDecorator < Representable::Decorator
      include Representable::Hash
      self.representation_wrap = :bands # wrap set!

      property :name
    end

    class AlbumDecorator < Representable::Decorator
      include Representable::Hash
      self.representation_wrap = :albums # wrap set!

      property :band, decorator: BandDecorator, wrap: false # you can now set :wrap to false!
    end

    album.to_hash #=> {"albums" => {"band" => {"name"=>"Social Distortion"}}}
    ```

    Thanks to @fighella for inspiring this feature when working on [roarify](https://github.com/fighella/roarify).
* `from_hash` no longer crashes with "NoMethodError: undefined method 'has_key?' for nil:NilClass" when an incoming nested object's value is `nil`. This was a problem with documents like `{song: nil}` where `song` is a nested property. Thanks to @mhuggins and @moxley for helping here.

# 2.2.3

* Introduce `Decorator::clone` to make sure cloning properly copies representable_attrs. in former versions, this would partially share definitions with subclasses when the decorator was an `inheritable_attr`.

# 2.2.2

* Bug fix: In 2.2.1 I accidentially removed a `super` call in `Representable::inherited` which leads to wrong behavior when having Representable mixed into a class along with other classes overriding `inherited`. Thanks to @jrmhaig for an [excellent bug report](https://github.com/apotonick/representable/issues/139#issuecomment-105926608) making it really easy to find the problem.

# 2.2.1

## API change.

* Options in `Definition` are now Cloneable. That means they will deep-clone when they contain values that are `Cloneable`. This allows clean cloning of deeply nested configuration hashes, e.g. for `deserializer: {instance: ->{}}` in combination with inheritance across representers.

  The former behavior was not to clone, which would allow sub-representers to bleed into the parent options, which is _wrong_. However, this fix shouldn't affect anyone but me.


# 2.2.0

## New Stuff

* Introduce `Representable::Cached` that will keep the mapper, which in turn will keep the bindings, which in turn will keep their representer, in case they're nested. You have to include this feature manually and you can expect a 50% and more speed-up for rendering and parsing. Not to speak about the reduced memory footprint.

  ```ruby
  class SongDecorator < Representable::Decorator
    include Representable::JSON
    feature Representable::Cached

    # ..
  end
  ```
* Introduced `Decorator#update!` to re-use a decorator instance between requests. This will inject the represented object, only.

  ```ruby
  decorator = SongDecorator.new(song)
  decorator.to_json(..)

  decorator.update!(louder_song)
  decorator.to_json(..)
  ```

  This is quite awesome.

## API change.

* The `:extend` option only accepts one module. `extend: [Module, Module]` does no longer work and it actually didn't work in former versions of 2.x, anyway, it just included the first element of an array.
* Remove `Binding#representer_module`.

# 2.1.8

* API change: features are now included into inline representers in the order they were specified. This used to be the other way round and is, of course, wrong, in case a sub-feature wants to override an existing method introduced by an earlier feature.

  ```ruby
  class Album < Representable::Decorator
    include Representable::Hash
    feature Title
    feature Date

    property :songs
      # will include R::Hash, Title, then Date.
  ```

As this is an edge-casey change, I decided _not_ to minor-version bump.

# 2.1.7

* Adding `Object#to_object`. This is even faster than using `#from_object` for simple transformations.

# 2.1.6

* Introducing `Representable::Object` that allows mapping objects to objects. This is way faster than rendering a hash from the source and then writing the hash to the target object.
* Fixed loading issues when requiring `representable/decorator`, only.

# 2.1.5

* Using `inherit: true` now works even if the parent property hasn't been defined before. It will simply create a new property. This used to crash with `undefined method `merge!' for nil:NilClass`.

  ```ruby
  class SongRepresenter < Representable::Decorator
    property :title, inherit: true # this will create a brand-new :title property.
  end
  ```

# 2.1.4

* Allow lonely collection representers without configuration, with inline representer, only. This is for render-only collection representers and very handy.
* Now runs with MagLev.

# 2.1.3

* Like 2.1.2 (got yanked) because I thought it's buggy but it's not. What has changed is that `Serializer::Collection#serialize` no longer does `collection.collect` but `collection.each` since this allows filtering out unwanted elements.

# 2.1.2

* Added `:skip_render` options.

# 2.1.1

* Added `Definition#delete!` to remove options.
* Added `Representable::apply` do iterate and change schemas.
* Added `Config#remove` to remove properties.
* Added `Representable::Debug` which just has to be included into your represented object.

    ```ruby
    song.extend(SongRepresenter).extend(Representable::Debug).from_json("..")
    song.extend(SongRepresenter).extend(Representable::Debug).to_json("..")
    ```

    It can also be included statically into your representer or decorator.

    ```ruby
    class SongRepresenter < Representable::Decorator
      include Representable::JSON
      include Representable::Debug

      property :title
    end
    ```

    It is great.

# 2.1.0

## Breaking Changes

* None, unless you messed around with internals like `Binding`.

## Changes

* Added `:skip_parse` to skip deserialization of fragments.
* It's now `Binding#read_fragment -> Populator -> Deserializer`. Mostly, this got changed to allow better support for complex collection semantics when populating/deserializing as found in Object-HAL.
* Likewise, it is `Binding#write_fragment -> Serializer`, clearly separating format-specific and generic logic.
* Make `Definition#inspect` more readable by filtering out some instance variables like `@runtime_options`.
* Remove `Binding#write_fragment_for`. This is `#render_fragment` now.
* Almost 100% speedup for rendering and parsing by removing Ruby's delegation and `method_missing`.
* Bindings are now in the following naming format: `Representable::Hash::Binding[::Collection]`. The file name is `representable/hash/binding`.
* Move `Definition#skipable_empty_value?` and `Definition#default_for` to `Binding` as it is runtime-specific.

# 2.0.4

* Fix implicit rendering of JSON and XML collections where json/collection wasn't loaded properly, resulting in the native JSON's `#to_json` to be called.
* Fix `:find_or_instantiate` parse strategy which wouldn't instantiate but raise an error. Thanks to @d4rky-pl.

# 2.0.3

* Fixed a bug where `Forwardable` wasn't available (because we didn't require it :).

# 2.0.2

* Fixed a bug with `Config#[]` which returned a default value that shouldn't be there.

# 2.0.1

* Made is simpler to define your own `Definition` class by passing it to `Config.new(Definition)` in `Representer::build_config`.

# 2.0.0

## Relevant

* Removed class methods `::from_json`, `::from_hash`, `::from_yaml` and `::from_xml`. Please build the instance yourself and use something along `Song.new.from_json`.
* Inline representers in `Decorator` do *no longer inherit from `self`*. When defining an inline representer, they are always derived from `Representable::Decorator`. The base class can be changed by overriding `Decorator::default_inline_class` in the decorator class that defines an inline representer block.
If you need to inherit common methods to all inline decorators, include the module using `::feature`: `Representer.feature(BetterProperty)`.
* You can now define methods in inline representers! The block is now `module_eval`ed and not `instance_exec`ed anymore. Same goes for Decorators, note that you need to `exec_context: :decorator`, though. Here, the block is `class_eval`ed.
* Removed behaviour for `instance: lambda { |*| nil }` which used to return `binding.get`. Simply do it yourself: `instance: lambda { |fragment, options| options.binding.get }` if you need this behaviour. If you use `:instance` and it returns `nil` it throws a `DeserializeError` now, which is way more understandable than `NoMethodError: undefined method 'title=' for {"title"=>"Perpetual"}:Hash`.
* Remove behaviour for `class: lambda { nil }` which used to return the fragment. This now throws a `DeserializeError`. Do it yourself with `class: lambda { |fragment,*| fragment }`.
* Coercion now happens inside `:render_filter` and `:parse_filter` (new!) and doesn't block `:getter` and `:setter` anymore. Also, we require virtus >=1.0 now.
* `::representation_wrap=` in now properly inherited.
* Including modules with representable `property .., inherit: true` into a `Decorator` crashed. This works fine now.

## New Stuff

* Added `::for_collection` to automatically generate a collection representer for singular one. Thanks to @timoschilling for inspiring this years ago.
* Added `::represent` that will detect collections and render the singular/collection with the respective representer.
* Added `Callable` options.
* Added `:parse_filter` and `:render_filter`.

## Internals

* Added `Representable::feature` to include a module and register it to be included into inline representers.
* New signature: `inline_representer(base, features, name, options, &block)`.
* Removed `::representer_engine`, the module to include is just another `register_feature` now.
* `Config` no longer is a Hash, it's API is limited to a few methods like `#<<`, `#[]` etc. It still supports the `Enumberable` interface.
* Moved `Representable::ClassMethods::Declarations` to `Representable::Declarative`.
* Moved `Representable::ClassMethods` to `Representable::Declarative`.
* Fixed: Inline decorators now work with `inherit: true`.
* Remove `:extend` in combination with inline representer. The `:extend` option is no longer considered. Include the module directly into the inline block.
* Deprecated class methods `::from_json` and friends. Use the instance version on an instance.
* Use uber 0.0.7 so we can use `Uber::Callable`.
* Removed `Decorator::Coercion`.
* Removed `Definition#skipable_nil_value?`.

# 1.8.5

* Binding now uses `#method_missing` instead of SimpleDelegator for a significant performance boost of many 100%s. Thanks to @0x4a616d6573 for figuring this.

# 1.8.4

* Make `representable/json` work without having to require `representable/hash`. Thanks to @acuppy!!!

# 1.8.3

* Fix `JSON::Collection` and `JSON::Hash` (lonely arrays and hashes), they can now use inline representers. Thanks to @jandudulski for reporting.
* Added `:render_empty` option to suppress rendering of empty collections. This will default to true in 2.0.
* Remove Virtus deprecations.
* Add support for Rubinius.
* `Definition#default` is public now, please don't use it anyway, it's a private concept.

# 1.8.1

* Add `:serialize` and `:deserialize` options for overriding those steps.

# 1.8.0

## Major Breakage

* `:if` receives block arguments just like any other dynamic options. Refer to **Dynamic Options**.
* Remove defaults for collections. This fixes a major design flaw - when parsing a document a collection would be reset to `[]` even if it is not present in the parsed document.
* The number of arguments per block might have changed. Generally, if you're not interested in block arguments, use `Proc.new` or `lambda { |*| }`. See **Dynamic Options**.


## Dynamic Options

* The following options are dynamic now and can either be a static value, a lambda or an instance method symbol: `:as`, `:getter`, `:setter`, `:class`, `:instance`, `:reader`, `:writer`, `:extend`, `:prepare`, `:if`. Please refer to the README to see their signatures.
* `representation_wrap` is dynamic, too, allowing you to change the wrap per instance.


## Cool New Stuff

* When unsure about the number of arguments passed into an option lambda, use `:pass_options`. This passes all general options in a dedicated `Options` object that responds to `binding`, `decorator`, `represented` and `user_options`. It's always the last argument for the block.
* Added `parse_strategy: :find_or_instantiate`. More to come.
* Added `parse_strategy: lambda { |fragment, i, options| }` to implement your own deserialization.
* Use `representable: false` to prevent calling `to_*/from_*` on a represented object even if the property is `typed?` (`:extend`, `:class` or `:instance` set).
* Introduced `:use_decorator` option to force an inline representer to be implemented with a Decorator even in a module. This fixes a bug since we used the `:decorate` option in earlier versions, which was already used for something else.
* Autoload `Representable::Hash*` and `Representable::Decorator`.
* Added `Representable::Hash::AllowSymbols` to convert symbol keys to strings in `from_hash`.


## Deprecations
* `decorator_scope: true` is deprecated, use `exec_context: :decorator` instead.
* Using `:extend` in combination with an inline representer is deprecated. Include the module in the block.
* `instance: lambda { true }` is deprecated. Use `parse_strategy: :sync`.
* Removed `Config#wrap`. Only way to retrieve the evaluated wrap is `Config#wrap_for`.
* `class: lambda { nil }` is deprecated. To return the fragment from parsing, use `instance: lambda { |fragment, *args| fragment }` instead.

## Definition

* Make `Definition < Hash`, all options can/should now be accessed with `Definition#[]`.
* Make `Definition::new` and `#merge!` the only entry points so that a `Definition` becomes an almost *immutual* object. If you happened to modify a definition using `options[..]=` this will break now. Use `definition.merge!(..)` to change it after creation.
* Deprecated `#options` as the definition itself is a hash (e.g. `definition[:default]`).
* Removed `#sought_type`, `#default`, `#attribute`, `#content`.
* `#from` is replaced by `#as` and hardcore deprecated.
* `#name` and `#as` are _always_ strings.
* A Definition is considered typed as soon as [`:extend`|`:class`|`:instance`] is set. In earlier versions, `property :song, class: Song` was considered typed, whereas `property :song, class: lambda { Song }` was static.


h2. 1.7.7

* Parsing an empty hash with a representer having a wrap does no longer throw an exception.
* `::nested` now works in modules, too! Nests are implemented as decorator representer, not as modules, so they don't pollute the represented object.
* Introduce `:inherit` to allow inheriting+overriding properties and inline representers (and properties in inline representers - it starts getting crazy!!!).

h2. 1.7.6

* Add `::nested` to nest blocks in the document whilst still using the same represented object. Use with `Decorator` only.
* Fixing a bug (thanks @rsutphin) where inline decorators would inherit the properties from the outer decorator.

h2. 1.7.5

* propagate all options for ::property to ::inline_representer.

h2. 1.7.3

* Fix segfaulting with XML by passing the document to nested objects. Reported by @timoschilling and fixed by @canadaduane.

h2. 1.7.2

* `Representable#update_properties_from` is private now.
* Added the `:content` option in XML to map top-level node's content to a property.

h2. 1.7.1

* Introduce `Config#options` hash to store per-representer configuration.
* The XML representer can now automatically remove namespaces when parsing. Use `XML::remove_namespaces!` in your representer. This is a work-around until namespaces are properly implemented in representable.

h2. 1.7.0

* The actual serialization and deserialization (that is, calling `to_hash` etc on the object) now happens in dedicated classes: `ObjectDeserializer` and friends. If you used to override stuff in `Binding`, I'm sorry.
* A new option `parse_strategy: :sync`. Instead of creating a new object using the `:class` option when parsing, it uses the original object found in the represented instance. This works for property and collections.
* `Config` is now a hash. You may find a particular definition by using `Config#[]`.
* Properties are now overridden: when calling `property(:title)` multiple times with the same name, this will override the former `Definition`. While this slightly changes the API, it allows overriding properties cleanly in sub-representers and saves you from manually finding and fiddling with the definitions.

h2. 1.6.1

* Using `instance: lambda { nil }` will now treat the property as a representable object without trying to extend it. It simply calls `to_*/from_*` on the property.
* You can use an inline representer and still have a `:extend` which will be automatically included in the inline representer. This is handy if you want to "extend" a base representer with an inline block. Thanks to @pixelvitamina for requesting that.
* Allow inline representers with `collection`. Thanks to @rsutphin!

h2. 1.6.0

* You can define inline representers now if you don't wanna use multiple modules and files.
<!-- here comes some code -->
```ruby
property :song, class: Song do
  property :title
end
```

This supersedes the use for `:extend` or `:decorator`, which still works, of course.

* Coercion now happens in a dedicated coercion object. This means that in your models virtus no longer creates accessors for coerced properties and thus values get coerced when rendering or parsing a document, only. If you want the old behavior, include `Virtus` into your model class and do the coercion yourself.
* `Decorator::Coercion` is deprecated, just use `include Representable::Coercion`.
* Introducing `Mapper` which does most of the rendering/parsing process. Be careful, if you used to override private methods like  `#compile_fragment` this no longer works, you have to override that in `Mapper` now.
* Fixed a bug where inheriting from Decorator wouldn't inherit properties correctly.

h2. 1.5.3

* `Representable#update_properties_from` now always returns `represented`, which is `self` in a module representer and the decorated object in a decorator (only the latter changed).
* Coercion in decorators should work now as expected.
* Fixed a require bug.

h2. 1.5.2

* Rename `:representer_exec` to `:decorator_scope` and make it a documented (!) feature.
* Accessors for properties defined with `decorator_scope: true` will now be invoked on the decorator, not on the represented instance anymore. This allows having decorators with helper methods.
* Use `MultiJson` instead of `JSON` when parsing and rendering.
* Make `Representable::Decorator::Coercion` work.

h2. 1.5.1

* Make lonely collections and hashes work with decorators.

h2. 1.5.0

* All lambdas now receive user options, too. Note that this might break your existing lambdas (especially with `:extend` or `:class`) raising an `ArgumentError: wrong number of arguments (2 for 1)`. Fix this by declaring your block params correctly, e.g. `lambda { |name, *|`. Internally, this happens by running all lambdas through the new `Binding#represented_exec_for`.

h2. 1.4.2

* Fix the processing of `:setter`, we called both the setter lambda and the setter method.

h2. 1.4.1

* Added `:representer_exec` to have lambdas be executed in decorator instance context.

h2. 1.4.0

* We now have two strategies for representing: the old extend approach and the brand-new decorator which leaves represented objects untouched. See "README":https://github.com/apotonick/representable#decorator-vs-extend for details.
* Internally, either extending or decorating in the Binding now happens through the representer class method `::prepare` (i.e. `Decorator::prepare` or `Representable::prepare` for modules). That means any representer module or class must expose this class method.

h2. 1.3.5

* Added `:reader` and `:writer` to allow overriding rendering/parsing of a property fragment and to give the user access to the entire document.

h2. 1.3.4

* Replacing `json` gem with `multi_json` hoping not to cause trouble.

h2. 1.3.3

* Added new options: `:binding`, `:setter` and `:getter`.
* The `:if` option now eventually receives passed in user options.

h2. 1.3.2

* Some minor internal changes. Added `Config#inherit` to encasulate array push behavior.

h2. 1.3.1

* Bringing back `:as`. For some strange reasons "we" lost that commit from @csexton!!!

h2. 1.3.0

* Remove @:exclude@ option.
* Moving all read/write logic to @Binding@. If you did override @#read_fragment@ and friends in your representer/models this won't work anymore.
* Options passed to @to_*/from_*@ are now passed to nested objects.

h2. 1.2.9

* When @:class@ returns @nil@ we no longer try to create a new instance but use the processed fragment itself.
* @:instance@ allows overriding the @ObjectBinding#create_object@ workflow by returning an instance from the lambda. This is particularly helpful when you need to inject additional data into the property object created in #deserialize.
* @:extend@ and @:class@ now also accept procs which allows having polymorphic properties and collections where representer and class can be chosen at runtime.

h2. 1.2.8

* Reverting all the bullshit from 1.2.7 making it even better. @Binding@s now wrap their @Definition@ instance adopting its API. Moved the binding_for_definition mechanics to the respecting @Binding@ subclass.
* Added :readable and :writeable to #property: while @:readable => true@ renders the property into the document @:writeable => true@ allows updating the property's value when consuming a representation. Both default to @true@.

h2. 1.2.7

* Moving @Format.binding_for_definition@ to @Format#{format}_binding_for_definition@, making it an instance method in its own "namespace". This allows mixing in multiple representer engines into a user's representer module.

h2. 1.2.6

* Extracted @HashRepresenter@ which operates on hash structures. This allows you to "parse" form data, e.g. as in Rails' @params@ hash. Internally, this is used by JSON and partly by YAML.

h2. 1.2.5

* Add support for YAML.

h2. 1.2.4

* ObjectBinding no longer tries to extend nil values when rendering and @:render_nil@ is set.
* In XML you can now use @:wrap@ to define an additional container tag around properties and collections.

h2. 1.2.3

* Using virtus for coercion now works in both classes and modules. Thanks to @solnic for a great collaboration. Open-source rocks!

h2. 1.2.2

* Added @XML::AttributeHash@ to store hash key-value pairs in attributes instead of dedicated tags.
* @JSON::Hash@, @XML::Hash@ and @XML::AttributeHash@ now respect @:exclude@ and @:include@ when parsing and rendering.

h2. 1.2.1

* Deprecated @:represent_nil@ favor of @:render_nil@.
* API change: if a property is missing in an incoming document and there is no default set it is completely ignored and *not* set in the represented object.


h2. 1.2.0

* Deprecated @:except@ in favor of @:exclude@.
* A property with @false@ value will now be included in the rendered representation. Same applies to parsing, @false@ values will now be included. That particularly means properties that used to be unset (i.e. @nil@) after parsing might be @false@ now.
* You can include @nil@ values now in your representations since @#property@ respects @:represent_nil => true@.

h2. 1.1.6

* Added @:if@ option to @property@.

h2. 1.1.5

* Definitions are now properly cloned when @Config@ is cloned.

h2. 1.1.4

* representable_attrs is now cloned when a representer module is included in an inheriting representer.

h2. 1.1.3

* Introduced `#compile_fragment` and friends to make it simpler overriding parsing and rendering steps.

h2. 1.1.2

* Allow `Module.hash` to be called without arguments as this seems to be required in Padrino.

h2. 1.1.1

* When a representer module is extended we no longer set the <code>@representable_attrs</code> ivar directly but use a setter. This makes it work with mongoid and fixes https://github.com/apotonick/roar/issues/10.

h2. 1.1.0

* Added `JSON::Collection` to have plain list representations. And `JSON::Hash` for hashes.
* Added the `hash` class method to XML and JSON to represent hashes.
* Defining `:extend` only on a property now works for rendering. If you try parsing without a `:class` there'll be an exception, though.

h2. 1.0.1

* Allow passing a list of modules to :extend, like @:extend => [Ingredient, IngredientRepresenter]@.

h2. 1.0.0

* 1.0.0 release! Party time!

h2. 0.13.1

* Removed property :@name from @XML@ in favor of @:attribute => true@.

h2. 0.13.0

* We no longer create accessors in @Representable.property@ - you have to do this yourself using @attr_accessors@.

h2. 0.12.0

* @:as@ is now @:class@.

h2. 0.11.0

* Representer modules can now be injected into objects using @#extend@.
* The @:extend@ option allows setting a representer module for a typed property. This will extend the contained object at runtime roughly following the DCI pattern.
* Renamed @#representable_property@ and @#representable_collection@ to @#property@ and @#collection@ as we don't have to fear namespace collisions in modules.

h2. 0.10.3

* Added @representable_property :default => ...@ option which is considered for both serialization and deserialization. The default is applied when the value is @nil@. Note that an empty string ain't @nil@.
* @representable_attrs@ are now pushed to instance level as soon as possible.

h2. 0.10.2

* Added @representable_property :accessors => false@ option to suppress adding accessors.
* @Representable.representation_wrap@ is no longer inherited.
* Representers can now be defined in modules. They inherit to including modules.

h2. 0.10.1

* The block in @to_*@ and @from_*@ now yields the symbolized property name. If you need the binding/definition you gotta get it yourself.
* Runs with Ruby 1.8 and 1.9.

h2. 0.10.0

* Wrapping can now be set through @Representable.representation_wrap=@. Possible values are:
  * @false@: No wrapping. In XML context, this is undefined behaviour. Default in JSON.
  * @String@: Wrap with provided string.
  * @true@: compute wrapper from class name.

h2. 0.9.3

* Removed the @:as => [..]@ syntax in favor of @:array => true@.

h2. 0.9.2

* Arguments and block now successfully forwarded in @#from_*@.

h2. 0.9.1

* Extracted common serialization into @Representable#create_representation_with@ and deserialization into @#update_properties_from@.
* Both serialization and deserialization now accept a block to make them skip elements while iterating the property definitions.

h2. 0.9.0

h3. Changes
  * Removed the :tag option in favor of :from. The Definition#from method is now authorative for all name mappings.
  * Removed the active_support and i18n dependency.
