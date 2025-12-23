# Rails HTML Sanitizers

This gem is responsible for sanitizing HTML fragments in Rails applications. Specifically, this is the set of sanitizers used to implement the Action View `SanitizerHelper` methods `sanitize`, `sanitize_css`, `strip_tags` and `strip_links`.

Rails HTML Sanitizer is only intended to be used with Rails applications. If you need similar functionality but aren't using Rails, consider using the underlying sanitization library [Loofah](https://github.com/flavorjones/loofah) directly.


## Usage

### Sanitizers

All sanitizers respond to `sanitize`, and are available in variants that use either HTML4 or HTML5 parsing, under the `Rails::HTML4` and `Rails::HTML5` namespaces, respectively.

NOTE: The HTML5 sanitizers are not supported on JRuby. Users may programmatically check for support by calling `Rails::HTML::Sanitizer.html5_support?`.


#### FullSanitizer

```ruby
full_sanitizer = Rails::HTML5::FullSanitizer.new
full_sanitizer.sanitize("<b>Bold</b> no more!  <a href='more.html'>See more here</a>...")
# => Bold no more!  See more here...
```

or, if you insist on parsing the content as HTML4:

```ruby
full_sanitizer = Rails::HTML4::FullSanitizer.new
full_sanitizer.sanitize("<b>Bold</b> no more!  <a href='more.html'>See more here</a>...")
# => Bold no more!  See more here...
```

#### LinkSanitizer

```ruby
link_sanitizer = Rails::HTML5::LinkSanitizer.new
link_sanitizer.sanitize('<a href="example.com">Only the link text will be kept.</a>')
# => Only the link text will be kept.
```

or, if you insist on parsing the content as HTML4:

```ruby
link_sanitizer = Rails::HTML4::LinkSanitizer.new
link_sanitizer.sanitize('<a href="example.com">Only the link text will be kept.</a>')
# => Only the link text will be kept.
```


#### SafeListSanitizer

This sanitizer is also available as an HTML4 variant, but for simplicity we'll document only the HTML5 variant below.

```ruby
safe_list_sanitizer = Rails::HTML5::SafeListSanitizer.new

# sanitize via an extensive safe list of allowed elements
safe_list_sanitizer.sanitize(@article.body)

# sanitize only the supplied tags and attributes
safe_list_sanitizer.sanitize(@article.body, tags: %w(table tr td), attributes: %w(id class style))

# sanitize via a custom scrubber
safe_list_sanitizer.sanitize(@article.body, scrubber: ArticleScrubber.new)

# prune nodes from the tree instead of stripping tags and leaving inner content
safe_list_sanitizer = Rails::HTML5::SafeListSanitizer.new(prune: true)

# the sanitizer can also sanitize css
safe_list_sanitizer.sanitize_css('background-color: #000;')
```

### Scrubbers

Scrubbers are objects responsible for removing nodes or attributes you don't want in your HTML document.

This gem includes two scrubbers `Rails::HTML::PermitScrubber` and `Rails::HTML::TargetScrubber`.

#### `Rails::HTML::PermitScrubber`

This scrubber allows you to permit only the tags and attributes you want.

```ruby
scrubber = Rails::HTML::PermitScrubber.new
scrubber.tags = ['a']

html_fragment = Loofah.fragment('<a><img/ ></a>')
html_fragment.scrub!(scrubber)
html_fragment.to_s # => "<a></a>"
```

By default, inner content is left, but it can be removed as well.

```ruby
scrubber = Rails::HTML::PermitScrubber.new
scrubber.tags = ['a']

html_fragment = Loofah.fragment('<a><span>text</span></a>')
html_fragment.scrub!(scrubber)
html_fragment.to_s # => "<a>text</a>"

scrubber = Rails::HTML::PermitScrubber.new(prune: true)
scrubber.tags = ['a']

html_fragment = Loofah.fragment('<a><span>text</span></a>')
html_fragment.scrub!(scrubber)
html_fragment.to_s # => "<a></a>"
```

#### `Rails::HTML::TargetScrubber`

Where `PermitScrubber` picks out tags and attributes to permit in sanitization,
`Rails::HTML::TargetScrubber` targets them for removal. See https://github.com/flavorjones/loofah/blob/main/lib/loofah/html5/safelist.rb for the tag list.

**Note:** by default, it will scrub anything that is not part of the permitted tags from
loofah `HTML5::Scrub.allowed_element?`.

```ruby
scrubber = Rails::HTML::TargetScrubber.new
scrubber.tags = ['img']

html_fragment = Loofah.fragment('<a><img/ ></a>')
html_fragment.scrub!(scrubber)
html_fragment.to_s # => "<a></a>"
```

Similarly to `PermitScrubber`, nodes can be fully pruned.

```ruby
scrubber = Rails::HTML::TargetScrubber.new
scrubber.tags = ['span']

html_fragment = Loofah.fragment('<a><span>text</span></a>')
html_fragment.scrub!(scrubber)
html_fragment.to_s # => "<a>text</a>"

scrubber = Rails::HTML::TargetScrubber.new(prune: true)
scrubber.tags = ['span']

html_fragment = Loofah.fragment('<a><span>text</span></a>')
html_fragment.scrub!(scrubber)
html_fragment.to_s # => "<a></a>"
```

#### Custom Scrubbers

You can also create custom scrubbers in your application if you want to.

```ruby
class CommentScrubber < Rails::HTML::PermitScrubber
  def initialize
    super
    self.tags = %w( form script comment blockquote )
    self.attributes = %w( style )
  end

  def skip_node?(node)
    node.text?
  end
end
```

See `Rails::HTML::PermitScrubber` documentation to learn more about which methods can be overridden.

#### Custom Scrubber in a Rails app

Using the `CommentScrubber` from above, you can use this in a Rails view like so:

```ruby
<%= sanitize @comment, scrubber: CommentScrubber.new %>
```

### A note on HTML entities

__Rails HTML sanitizers are intended to be used by the view layer, at page-render time. They are *not* intended to sanitize persisted strings that will be sanitized *again* at page-render time.__

Proper HTML sanitization will replace some characters with HTML entities. For example, text containing a `<` character will be updated to contain `&lt;` to ensure that the markup is well-formed.

This is important to keep in mind because __HTML entities will render improperly if they are sanitized twice.__


#### A concrete example showing the problem that can arise

Imagine the user is asked to enter their employer's name, which will appear on their public profile page. Then imagine they enter `JPMorgan Chase & Co.`.

If you sanitize this before persisting it in the database, the stored string will be `JPMorgan Chase &amp; Co.`

When the page is rendered, if this string is sanitized a second time by the view layer, the HTML will contain `JPMorgan Chase &amp;amp; Co.` which will render as "JPMorgan Chase &amp;amp; Co.".

Another problem that can arise is rendering the sanitized string in a non-HTML context (for example, if it ends up being part of an SMS message). In this case, it may contain inappropriate HTML entities.


#### Suggested alternatives

You might simply choose to persist the untrusted string as-is (the raw input), and then ensure that the string will be properly sanitized by the view layer.

That raw string, if rendered in an non-HTML context (like SMS), must also be sanitized by a method appropriate for that context. You may wish to look into using [Loofah](https://github.com/flavorjones/loofah) or [Sanitize](https://github.com/rgrove/sanitize) to customize how this sanitization works, including omitting HTML entities in the final string.

If you really want to sanitize the string that's stored in your database, you may wish to look into  [Loofah::ActiveRecord](https://github.com/flavorjones/loofah-activerecord) rather than use the Rails HTML sanitizers.


### A note on module names

In versions < 1.6, the only module defined by this library was `Rails::Html`. Starting in 1.6, we define three additional modules:

- `Rails::HTML` for general functionality (replacing `Rails::Html`)
- `Rails::HTML4` containing sanitizers that parse content as HTML4
- `Rails::HTML5` containing sanitizers that parse content as HTML5 (if supported)

The following aliases are maintained for backwards compatibility:

- `Rails::Html` points to `Rails::HTML`
- `Rails::HTML::FullSanitizer` points to `Rails::HTML4::FullSanitizer`
- `Rails::HTML::LinkSanitizer` points to `Rails::HTML4::LinkSanitizer`
- `Rails::HTML::SafeListSanitizer` points to `Rails::HTML4::SafeListSanitizer`


## Installation

Add this line to your application's Gemfile:

    gem 'rails-html-sanitizer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-html-sanitizer


## Support matrix

| branch | ruby support | actively maintained | security support                       |
|--------|--------------|---------------------|----------------------------------------|
| 1.6.x  | >= 2.7       | yes                 | yes                                    |
| 1.5.x  | >= 2.5       | no                  | while Rails 6.1 is in security support |
| 1.4.x  | >= 1.8.7     | no                  | no                                     |


## Read more

Loofah is what underlies the sanitizers and scrubbers of rails-html-sanitizer.

- [Loofah and Loofah Scrubbers](https://github.com/flavorjones/loofah)

The `node` argument passed to some methods in a custom scrubber is an instance of `Nokogiri::XML::Node`.

- [`Nokogiri::XML::Node`](https://nokogiri.org/rdoc/Nokogiri/XML/Node.html)
- [Nokogiri](http://nokogiri.org)


## Contributing to Rails HTML Sanitizers

Rails HTML Sanitizers is work of many contributors. You're encouraged to submit pull requests, propose features and discuss issues.

See [CONTRIBUTING](CONTRIBUTING.md).

### Security reports

Trying to report a possible security vulnerability in this project? Please check out the [Rails project's security policy](https://rubyonrails.org/security) for instructions.


## License

Rails HTML Sanitizers is released under the [MIT License](MIT-LICENSE).
