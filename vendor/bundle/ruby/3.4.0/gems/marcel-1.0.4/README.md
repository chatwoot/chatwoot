# Marcel

Marcel attempts to choose the most appropriate content type for a given file by looking at the binary data, the filename, and any declared type (perhaps passed as a request header). This is done via the `Marcel::MimeType.for` method, and is used like this:

```ruby
Marcel::MimeType.for Pathname.new("example.gif")
#  => "image/gif"

File.open "example.gif" do |file|
  Marcel::MimeType.for file
end
#  => "image/gif"

Marcel::MimeType.for Pathname.new("unrecognisable-data"), name: "example.pdf"
#  => "application/pdf"

Marcel::MimeType.for extension: ".pdf"
#  => "application/pdf"

Marcel::MimeType.for Pathname.new("unrecognisable-data"), name: "example", declared_type: "image/png"
#  => "image/png"

Marcel::MimeType.for StringIO.new(File.read "unrecognisable-data")
#  => "application/octet-stream"
```

By preference, the magic number data in any passed in file is used to determine the type. If this doesn't work, it uses the type gleaned from the filename, extension, and finally the declared type. If no valid type is found in any of these, "application/octet-stream" is returned.

Some types aren't easily recognised solely by magic number data. For example Adobe Illustrator files have the same magic number as PDFs (and can usually even be viewed in PDF viewers!). For these types, Marcel uses both the magic number data and the file name to work out the type:

```ruby
Marcel::MimeType.for Pathname.new("example.ai"), name: "example.ai"
#  => "application/illustrator"
```

This only happens when the type from the filename is a more specific type of that from the magic number. If it isn't the magic number alone is used.

```ruby
Marcel::MimeType.for Pathname.new("example.png"), name: "example.ai"
#  => "image/png"
# As "application/illustrator" is not a more specific type of "image/png", the filename is ignored
```

Custom file types not supported by Marcel can be added using `Marcel::MimeType.extend`. 

```ruby
Marcel::MimeType.extend "text/custom", extensions: %w( customtxt )
Marcel::MimeType.for name: "file.customtxt"
#  => "text/custom"
```

## Motivation

Marcel was extracted from Basecamp 3, in order to make our file detection logic both easily reusable but more importantly, easily testable. Test fixtures have been added for all of the most common file types uploaded to Basecamp, and other common file types too. We hope to expand this test coverage with other file types as and when problems are identified.

## Contributing

Marcel generates MIME lookup tables with `bundle exec rake tables`. MIME types are seeded from data found in `data/*.xml`. Custom MIMEs may be added to `data/custom.xml`, while overrides to the standard MIME database may be added to `lib/marcel/mime_type/definitions.rb`.

Marcel follows the same contributing guidelines as [rails/rails](https://github.com/rails/rails#contributing).

## Testing

The main test fixture files are split into two folders, those that can be recognised by magic numbers, and those that can only be recognised by name. Even though strictly unnecessary, the fixtures in both folders should all be valid files of the type they represent.

## License

Marcel itself is released under the terms of the MIT License. See the MIT-LICENSE file for details.

Portions of Marcel are adapted from the [mimemagic] gem, released under the terms of the MIT License.

Marcel's magic signature data is adapted from [Apache Tika](https://tika.apache.org), released under the terms of the Apache License. See the APACHE-LICENSE file for details.

[mimemagic]: https://github.com/mimemagicrb/mimemagic
