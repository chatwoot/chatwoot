# ImageProcessing

Provides higher-level image processing helpers that are commonly needed
when handling image uploads.

This gem can process images with either [ImageMagick]/[GraphicsMagick] or
[libvips] libraries. ImageMagick is a good default choice, especially if you
are migrating from another gem or library that uses ImageMagick. Libvips is a
newer library that can process images [very rapidly][libvips performance]
(often multiple times faster than ImageMagick).


## Goal

The goal of this project is to have a single gem that contains all the
helper methods needed to resize and process images.

Currently, existing attachment gems (like Paperclip, CarrierWave, Refile,
Dragonfly, ActiveStorage, and others) implement their own custom image
helper methods. But why? That's not very DRY, is it?

Let's be honest. Image processing is a dark, mysterious art. So we want to
combine every great idea from all of these separate gems into a single awesome
library that is constantly updated with best-practice thinking about
how to resize and process images.


## Installation

1. Install ImageMagick and/or libvips:

In a Mac terminal:
  
```sh
  $ brew install imagemagick vips
  ```

 In a debian/ubuntu terminal:

```sh
  $ sudo apt install imagemagick libvips
  ```

2. Add the gem to your Gemfile:

  ```rb
  gem "image_processing", "~> 1.0"
  ```


## Usage

Processing is performed through **[`ImageProcessing::Vips`]** or
**[`ImageProcessing::MiniMagick`]** modules. Both modules share the same
chainable API for defining the processing pipeline:

```rb
require "image_processing/mini_magick"

processed = ImageProcessing::MiniMagick
  .source(file)
  .resize_to_limit(400, 400)
  .convert("png")
  .call

processed #=> #<Tempfile:/var/folders/.../image_processing20180316-18446-1j247h6.png>
```

This allows easy branching when generating multiple derivates:

```rb
require "image_processing/vips"

pipeline = ImageProcessing::Vips
  .source(file)
  .convert("png")

large  = pipeline.resize_to_limit!(800, 800)
medium = pipeline.resize_to_limit!(500, 500)
small  = pipeline.resize_to_limit!(300, 300)
```

The processing is executed on `#call` or when a processing method is called
with a bang (`!`).

```rb
processed = ImageProcessing::MiniMagick
  .convert("png")
  .resize_to_limit(400, 400)
  .call(image)

# OR

processed = ImageProcessing::MiniMagick
  .source(image) # declare source image
  .convert("png")
  .resize_to_limit(400, 400)
  .call

# OR

processed = ImageProcessing::MiniMagick
  .source(image)
  .convert("png")
  .resize_to_limit!(400, 400) # bang method
```

You can inspect the pipeline options at any point before executing it:

```rb
pipeline = ImageProcessing::MiniMagick
  .source(image)
  .loader(page: 1)
  .convert("png")
  .resize_to_limit(400, 400)
  .strip

pipeline.options
# => {:source=>#<File:/path/to/source.jpg>,
#     :loader=>{:page=>1},
#     :saver=>{},
#     :format=>"png",
#     :operations=>[[:resize_to_limit, [400, 400]], [:strip, []]],
#     :processor_class=>ImageProcessing::MiniMagick::Processor}
```

The source object needs to responds to `#path`, or be a String, a Pathname, or
a `Vips::Image`/`MiniMagick::Tool` object. Note that the processed file is
always saved to a new location, in-place processing is not supported.

```rb
ImageProcessing::Vips.source(File.open("source.jpg"))
ImageProcessing::Vips.source("source.jpg")
ImageProcessing::Vips.source(Pathname.new("source.jpg"))
ImageProcessing::Vips.source(Vips::Image.new_from_file("source.jpg"))
```

When `#call` is called without options, the result of processing is a
`Tempfile` object. You can save the processing result to a specific location by
passing `:destination` to `#call`, or pass `save: false` to retrieve the raw
`Vips::Image`/`MiniMagick::Tool` object.

```rb
pipeline = ImageProcessing::Vips.source(image)

pipeline.call #=> #<Tempfile ...>
pipeline.call(save: false) #=> #<Vips::Image ...>
pipeline.call(destination: "/path/to/destination")
```

You can continue reading the API documentation for specific modules:

* **[`ImageProcessing::Vips`]**
* **[`ImageProcessing::MiniMagick`]**

See the **[wiki]** for additional "How To" guides for common scenarios. The wiki
is publicly editable, so you're encouraged to add your own guides.

## Instrumentation

You can register an `#instrumenter` block for a given pipeline, which will wrap
the pipeline execution, allowing you to record performance metrics.

```rb
pipeline = ImageProcessing::Vips.instrumenter do |**options, &processing|
  options[:source]     #=> #<File:...>
  options[:loader]     #=> { fail: true }
  options[:saver]      #=> { quality: 85 }
  options[:format]     #=> "png"
  options[:operations] #=> [[:resize_to_limit, 500, 500], [:flip, [:horizontal]]]
  options[:processor]  #=> ImageProcessing::Vips::Processor

  ActiveSupport::Notifications.instrument("process.image_processing", **options) do
    processing.call # calls the pipeline
  end
end

pipeline
  .source(image)
  .loader(fail: true)
  .saver(quality: 85)
  .convert("png")
  .resize_to_limit(500, 500)
  .flip(:horizontal)
  .call # calls instrumenter
```

## Contributing

Our test suite requires both `imagemagick` and `libvips` libraries to be installed.

In a Mac terminal:

```
$ brew install imagemagick vips
```

In a debian/ubuntu terminal:
```shell
sudo apt install imagemagick libvips
```

Afterwards you can run tests with

```
$ bundle exec rake test
```


## Feedback

We welcome your feedback! What would you like to see added to image_processing?
How can we improve this gem? Open an issue and let us know!


## Credits

The `ImageProcessing::MiniMagick` functionality was extracted from
[refile-mini_magick]. The chainable interface was heavily inspired by
[HTTP.rb].


## License

[MIT](LICENSE.txt)

[libvips]: http://libvips.github.io/libvips/
[ImageMagick]: https://www.imagemagick.org
[GraphicsMagick]: http://www.graphicsmagick.org
[`ImageProcessing::Vips`]: doc/vips.md#readme
[`ImageProcessing::MiniMagick`]: doc/minimagick.md#readme
[refile-mini_magick]: https://github.com/refile/refile-mini_magick
[wiki]: https://github.com/janko/image_processing/wiki
[HTTP.rb]: https://github.com/httprb/http
[libvips performance]: https://github.com/libvips/libvips/wiki/Speed-and-memory-use
