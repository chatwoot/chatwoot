# Sprockets: Rack-based asset packaging

Sprockets is a Ruby library for compiling and serving web assets.
It features declarative dependency management for JavaScript and CSS
assets, as well as a powerful preprocessor pipeline that allows you to
write assets in languages like CoffeeScript, Sass and SCSS.

## Installation

Install Sprockets from RubyGems:

``` sh
$ gem install sprockets
```

Or include it in your project's `Gemfile` with Bundler:

``` ruby
gem 'sprockets', '~> 4.0'
```

## Upgrading to Sprockets 4.x

These are the major features in Sprockets 4.x

- Source Maps
- Manifest.js
- ES6 support
- Deprecated processor interface in 3.x is removed in 4.x

Read more about them by referencing [Upgrading document](UPGRADING.md)

## Guides

For most people interested in using Sprockets, you will want to see the README below.

If you are a framework developer that is using Sprockets, see [Building an Asset Processing Framework](guides/building_an_asset_processing_framework.md).

If you are a library developer who is extending the functionality of Sprockets, see [Extending Sprockets](guides/extending_sprockets.md).

If you want to work on Sprockets or better understand how it works read [How Sprockets Works](guides/how_sprockets_works.md)

## Behavior Overview

You can interact with Sprockets primarily through directives and file extensions. This section covers how to use each of these things, and the defaults that ship with Sprockets.

Since you are likely using Sprockets through another framework (such as the [the Rails asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html)), there will be configuration options you can toggle that will change behavior such as what directories or files get compiled. For that documentation you should see your framework's documentation.

#### Accessing Assets

Assets in Sprockets are always referenced by their *logical path*.

The logical path is the path of the asset source file relative to its
containing directory in the load path. For example, if your load path
contains the directory `app/assets/javascripts`:

<table>
  <tr>
    <th>Logical path</th>
    <th>Source file on disk</th>
  </tr>
  <tr>
    <td>application.js</td>
    <td>app/assets/javascripts/application.js</td>
  </tr>
  <tr>
    <td>models/project.js</td>
    <td>app/assets/javascripts/models/project.js</td>
  </tr>
  <tr>
    <td>hello.js</td>
    <td>app/assets/javascripts/hello.coffee</td>
  </tr>
</table>

> Note: For assets that are compiled or transpiled, you want to specify the extension that you want, not the extension on disk. For example we specified `hello.js` even if the file on disk is a coffeescript file, since the asset it will generate is javascript.

### Directives

Directives are special comments in your asset file and the main way of interacting with processors. What kind of interactions? You can use these directives to tell Sprockets to load other files, or specify dependencies on other assets.

For example, let's say you have custom JavaScript that you've written. You put this javascript in a file called `beta.js`. The javascript makes heavy use of jQuery, so you need to load that before your code executes. You could add a `require` directive to the top of `beta.js`:

```js
//= require jquery

$().ready({
  // my custom code here
})
```

The directive processor understands comment blocks in three formats:

``` css
/* Multi-line comment blocks (CSS, SCSS, JavaScript)
 *= require foo
 */
```

``` js
// Single-line comment blocks (SCSS, JavaScript)
//= require foo
```

``` coffee
# Single-line comment blocks (CoffeeScript)
#= require foo
```

> Note: Directives are only processed if they come before any application code. Once you have a line that does not include a comment or whitespace then Sprockets will stop looking for directives. If you use a directive outside of the "header" of the document it will not do anything, and won't raise any errors.

Here is a list of the available directives:

- [`require`](#require) - Add the contents of a file to current
- [`require_self`](#require_self) - Change order of where current contents are concatenated to current
- [`require_directory`](#require_directory) - Add contents of each file in a folder to current
- [`require_tree`](#require_tree) - Add contents of all files in all directories in a path to current
- [`link`](#link) - Make target file compile and be publicly available without adding contents to current
- [`link_directory`](#link_directory) - Make target directory compile and be publicly available without adding contents to current
- [`link_tree`](#link_tree) - Make target tree compile and be publicly available without adding contents to current
- [`depend_on`](#depend_on) - Recompile current file if target has changed
- [`depend_on_directory`](#depend_on_directory) - Recompile current file if any files in target directory has changed
- [`stub`](#stub) - Ignore target file

You can see what each of these does below.

### Specifying Processors through File Extensions

Sprockets uses the filename extensions to determine what processors to run on your file and in what order. For example if you have a file:

```
application.scss
```

Then Sprockets will by default run the sass processor (which implements scss). The output file will be converted to css.

You can specify multiple processors by specifying multiple file extensions. For example you can use Ruby's [ERB template language](#invoking-ruby-with-erb) to embed content in your doc before running the sass processor. To accomplish this you would need to name your file

```
application.scss.erb
```

Processors are run from right to left (tail to head), so in the above example the processor associated with `erb` will be run before the processor associated with `scss` extension.

For a description of the processors that Sprockets has by default see the "default processors" section below. Other libraries may register additional processors.

When "asking" for a compiled file, you always ask for the extension you want. For example if you're using Rails, to get the contents of `application.scss.erb` you would use

```
asset_path("application.css")
```

Sprockets understands that `application.scss.erb` will compile down to a `application.css`. Ask for what you need, not what you have.

If this isn't working like you expect, make sure you didn't typo an extension, and make sure the file is on a "load path" (see framework docs for adding new load paths).

## File Order Processing

By default files are processed in alphabetical order. This behavior can impact your asset compilation when one asset needs to be loaded before another.

For example if you have an `application.js` and it loads another directory

```js
//= require_directory my_javascript
```

The files in that directory will be loaded in alphabetical order. If the directory looks like this:

```sh
$ ls -1 my_javascript/

alpha.js
beta.js
jquery.js
```

Then `alpha.js` will be loaded before either of the other two. This can be a problem if `alpha.js` uses jquery. For this reason it is not recommend to use `require_directory` with files that are ordering dependent. You can either require individual files manually:

```js
//= require jquery
//= require alpha
//= require beta
```

Or you can use index files to proxy your folders.

### Index files are proxies for folders

In Sprockets index files such as `index.js` or `index.css` files inside of a folder will generate a file with the folder's name. So if you have a `foo/index.js` file it will compile down to `foo.js`. This is similar to NPM's behavior of using [folders as modules](https://nodejs.org/api/modules.html#modules_folders_as_modules). It is also somewhat similar to the way that a file in `public/my_folder/index.html` can be reached by a request to `/my_folder`. This means that you cannot directly use an index file. For example this would not work:

```erb
<%= asset_path("foo/index.js") %>
```

Instead you would need to use:

```erb
<%= asset_path("foo.js") %>
```

Why would you want to use this behavior?  It is common behavior where you might want to include an entire directory of files in a top level JavaScript. You can do this in Sprockets using `require_tree .`

```js
//= require_tree .
```

This has the problem that files are required alphabetically. If your directory has `jquery-ui.js` and `jquery.min.js` then Sprockets will require `jquery-ui.js` before `jquery` is required which won't work (because jquery-ui depends on jquery). Previously the only way to get the correct ordering would be to rename your files, something like `0-jquery-ui.js`. Instead of doing that you can use an index file.

For example, if you have an `application.js` and want all the files in the `foo/` folder you could do this:

```js
//= require foo.js
```

Then create a file `foo/index.js` that requires all the files in that folder in any order you want using relative references:

```js
//= require ./foo.min.js
//= require ./foo-ui.js
```

Now in your `application.js` will correctly load the `foo.min.js` before `foo-ui.js`. If you used `require_tree` it would not work correctly.

## Cache

Compiling assets is slow. It requires a lot of disk use to pull assets off of hard drives, a lot of RAM to manipulate those files in memory, and a lot of CPU for compilation operations. Because of this Sprockets has a cache to speed up asset compilation times. That's the good news. The bad news, is that sprockets has a cache and if you've found a bug it's likely going to involve the cache.

By default Sprockets uses the file system to cache assets. It makes sense that Sprockets does not want to generate assets that already exist on disk in `public/assets`, what might not be as intuitive is that Sprockets needs to cache "partial" assets.

For example if you have an `application.js` and it is made up of `a.js`, `b.js`, all the way to `z.js`

```js
//= require a.js
//= require b.js
# ...
//= require z.js
```

The first time this file is compiled the `application.js` output will be written to disk, but also intermediary compiled files for `a.js` etc. will be written to the cache directory (usually `tmp/cache/assets`).

So, if `b.js` changes it will get recompiled. However instead of having to recompile the other files from `a.js` to `z.js` since they did not change, we can use the prior intermediary files stored in the cached values . If these files were expensive to generate, then this "partial" asset cache strategy can save a lot of time.

Directives such as `require`, `link`, `depend_on`, and `depend_on_directory` tell Sprockets what assets need to be re-compiled when a file changes. Files are considered "fresh" based on their mtime on disk and a combination of cache keys.

On Rails you can force a "clean" install by clearing the `public/assets` and `tmp/cache/assets` directories.


## Default Directives

Directives take a path or a path to a file. Paths for directive can be relative to the current file, for example:

```js
//= require ../foo.js
```

This would load the file up one directory and named `foo.js`. However this isn't required if `foo.js` is on one of Sprocket's load paths. You can simply use

```js
//= require foo.js
```

Without any prepended dots and sprockets will search for the asset. If the asset is on a sub-path of the load path, you can specify it without using a relative path as well:

```js
//= require sub/path/foo.js
```

You can also use an absolute path, but this is discouraged unless you know the directory structure of every machine you plan on running code on.

Below is a section for each of the built in directive types supported by Sprockets.

### require

`require` *path* inserts the contents of the asset source file
specified by *path*. If the file is required multiple times, it will
appear in the bundle only once.

**Example:**

If you've got an `a.js`:

```js
var a = "A";
```

and a `b.js`;

```js
var b = "B";
```

Then you could require both of these in an `application.js`

```js
//= require a.js
//= require b.js
```

Which would generate one concatenated file:

```js
var a = "A";
var b = "B";
```

### require_self

`require_self` tells Sprockets to insert the body of the current
source file before any subsequent `require` directives.

**Example:**

If you've got an `a.js`:

```js
var a = "A";
```

And an `application.js`

```js
//= require_self
//= require 'a.js'

var app_name = "Sprockets";
```

Then this will take the contents of `application.js` (that come after the last require) and put them at the beginning of the file:

```js
var app_name = "Sprockets";
var a = "A";
```

### require_directory

`require_directory` *path* requires all source files of the same
format in the directory specified by *path*. Files are required in
alphabetical order.

**Example:**

If we've got a directory called `alphabet` with an `a.js` and `b.js` files like before, then our `application.js`

```js
//= require_directory alphabet
```

Would produce:

```js
var a = "A";
var b = "B";
```

You can also see [Index files are proxies for folders](#index-files-are-proxies-for-folders) for another method of organizing folders that will give you more control.

### require_tree

`require_tree` *path* works like `require_directory`, but operates
recursively to require all files in all subdirectories of the
directory specified by *path*.

### link

`link` *path* declares a dependency on the target *path* and adds it to a list
of subdependencies to be compiled when the asset is written out to
disk.

Example:

If you've got a `manifest.js` file and you want to specify that a `admin.js` source file should be
generated and made available to the public you can link it by including this in the `manifest.js` file:

```
//= link admin.js
```

The argument to `link` is a _logical path_, that is it will be resolved according to the
configured asset load paths. See [Accessing Assets](#accessing-assets) above. A path relative to
the current file won't work, it must be a logical path.

**Caution**: the "link" directive should always have an explicit extension on the end.

`link` can also be used to include manifest files from mounted Rails engines:

```
//= link my_engine_manifest
```

This would find a manifest file at `my_engine/app/assets/config/my_engine_manifest.js` and include its directives.

### link_directory

`link_directory` *path* links all the files inside the directory specified by the *path*. By "link", we mean they are specified as compilation targets to be written out to disk, and made available to be served to user-agents.

Files in subdirectories will not be linked (Compare to [link_tree](#link_tree)).

The *path* argument to `link_directory` is _not_ a logical path (it does not use the asset load paths), but is a path relative to the file the `link_directory` directive is found in, and can use `..` to  . For instance, you might want:

```js
//= link_directory ../stylesheets
```

`link_directory` can take an optional second argument with an extension or content-type, with the
two arguments separated by a space:

```js
//= link_directory ../stylesheets text/css
//= link_directory ../more_stylesheets .css
```

This will limit the matching files to link to only files recognized as that type. An extension is
just a shortcut for the type referenced, it does not need to match the source file exactly, but
instead identifies the content-type the source file must be recognized as.

### link_tree

`link_tree` *path* works like [link_directory](#link_directory), but operates
recursively to link all files in all subdirectories of the
directory specified by *path*.

Example:

```js
//= link_tree ./path/to/folder
```

Like `link_directory`, the argument is path relative to the current file, it is *not* a 'logical path' tresolved against load paths.


As with `link_directory`, you can also specify a second argument -- separated by a space --  so any extra files not matching the content-type specified will be ignored:

```js
//= link_tree ./path/to/folder text/javascript
//= link_tree ./path/to/other_folder .js
```


### depend_on

`depend_on` *path* declares a dependency on the given *path* without
including it in the bundle. This is useful when you need to expire an
asset's cache in response to a change in another file.

**Example:**

If you have a file such as `bar.data` and you're using data from that file in another file, then
you need to tell sprockets that it needs to re-compile the file if `bar.data` changes:

```js
//= depend_on "bar.data"

var bar = '<%= File.read("bar.data") %>'
```

To depend on an entire directory containing multiple files, use `depend_on_directory`

### depend_on_asset

`depend_on_asset` *path* works like `depend_on`, but operates
recursively reading the file and following the directives found. This is automatically implied if you use `link`, so consider if it just makes sense using `link` instead of `depend_on_asset`.

### depend_on_directory

`depend_on_directory` *path* declares all files in the given *path* without
including them in the bundle. This is useful when you need to expire an
asset's cache in response to a change in multiple files in a single directory.

All paths are relative to your declaration and must begin with `./`

Also, your must include these directories in your [load path](guides/building_an_asset_processing_framework.md#the-load-path).

**Example:**

If we've got a directory called `data` with files `a.data` and `b.data`

```
// ./data/a.data
A
```

```
// ./data/b.data
B
```

```
// ./file.js.erb
//= depend_on_directory ./data
var a = '<% File.read('data/a.data') %>'
var b = '<% File.read('data/b.data') %>'
```

Would produce:

```js
var a = "A";
var b = "B";
```

You can also see [Index files are proxies for folders](#index-files-are-proxies-for-folders) for another method of organizing folders that will give you more control.

### stub

`stub` *path* excludes that asset and its dependencies from the asset bundle.
The *path* must be a valid asset and may or may not already be part
of the bundle. `stub` should only be used at the top level bundle, not
within any subdependencies.

### Invoking Ruby with ERB

Sprockets provides an ERB engine for preprocessing assets using
embedded Ruby code. Append `.erb` to a CSS or JavaScript asset's
filename to enable the ERB engine.

For example if you have an `app/application/javascripts/app_name.js.erb`
you could have this in the template

```js
var app_name = "<%= ENV['APP_NAME'] %>";
```

Generated files are cached. If you're using an `ENV` var then
when you change then ENV var the asset will be forced to
recompile. This behavior is only true for environment variables,
if you are pulling a value from somewhere else, such as a database,
you must manually invalidate the cache to see the change.

If you're using Rails, there are helpers you can use such as `asset_url`
that will cause a recompile if the value changes.

For example if you have this in your `application.css`

``` css
.logo {
  background: url(<%= asset_url("logo.png") %>)
}
```

When you modify the `logo.png` on disk, it will force `application.css` to be
recompiled so that the fingerprint will be correct in the generated asset.

You can manually make sprockets depend on any other file that is generated
by sprockets by using the `depend_on` or `depend_on_directory` directive. Rails
implements the above feature by auto calling `depend_on` on the original asset
when the `asset_url` is used inside of an asset.

### Styling with Sass and SCSS

[Sass](http://sass-lang.com/) is a language that compiles to CSS and
adds features like nested rules, variables, mixins and selector
inheritance.

If the `sass` gem is available to your application, you can use Sass
to write CSS assets in Sprockets.

Sprockets supports both Sass syntaxes. For the original
whitespace-sensitive syntax, use the extension `.sass`. For the
new SCSS syntax, use the extension `.scss`.

In Rails if you have `app/application/stylesheets/foo.scss` it can
be referenced with `<%= asset_path("foo.css") %>`. When referencing
an asset in Rails, always specify the extension you want. Sprockets will
convert `foo.scss` to `foo.css`.

### Scripting with CoffeeScript

[CoffeeScript](http://jashkenas.github.io/coffeescript/) is a
language that compiles to the "good parts" of JavaScript, featuring a
cleaner syntax with array comprehensions, classes, and function
binding.

If the `coffee-script` gem is available to your application, you can
use CoffeeScript to write JavaScript assets in Sprockets. Note that
the CoffeeScript compiler is written in JavaScript, and you will need
an [ExecJS](https://github.com/rails/execjs)-supported runtime
on your system to invoke it.

To write JavaScript assets with CoffeeScript, use the extension
`.coffee`.

In Rails if you have `app/application/javascripts/foo.coffee` it can
be referenced with `<%= asset_path("foo.js") %>`. When referencing
an asset in Rails, always specify the extension you want. Sprockets will
convert `foo.coffee` to `foo.js`.


## ES6 Support

Sprockets 4 ships with a Babel processor. This allows you to transpile ECMAScript6 to JavaScript just like you would transpile CoffeeScript to JavaScript. To use this, modify your Gemfile:

```ruby
gem 'babel-transpiler'
```

Any asset with the extension `es6` will be treated as an ES6 file:

```es6
// app/assets/javascript/application.es6

var square = (n) => n * n

console.log(square);
```

Start a Rails server in development mode and visit `localhost:3000/assets/application.js`, and this asset will be transpiled to JavaScript:

```js
var square = function square(n) {
  return n * n;
};

console.log(square);
```


### JavaScript Templating with EJS and Eco

Sprockets supports *JavaScript templates* for client-side rendering of
strings or markup. JavaScript templates have the special format
extension `.jst` and are compiled to JavaScript functions.

When loaded, a JavaScript template function can be accessed by its
logical path as a property on the global `JST` object. Invoke a
template function to render the template as a string. The resulting
string can then be inserted into the DOM.

```
<!-- templates/hello.jst.ejs -->
<div>Hello, <span><%= name %></span>!</div>

// application.js
//= require templates/hello
$("#hello").html(JST["templates/hello"]({ name: "Sam" }));
```

Sprockets supports two JavaScript template languages:
[EJS](https://github.com/sstephenson/ruby-ejs), for embedded
JavaScript, and [Eco](https://github.com/sstephenson/ruby-eco), for
embedded CoffeeScript. Both languages use the familiar `<% … %>`
syntax for embedding logic in templates.

If the `ejs` gem is available to your application, you can use EJS
templates in Sprockets. EJS templates have the extension `.jst.ejs`.

If the `eco` gem is available to your application, you can use [Eco
templates](https://github.com/sstephenson/eco) in Sprockets. Eco
templates have the extension `.jst.eco`. Note that the `eco` gem
depends on the CoffeeScript compiler, so the same caveats apply as
outlined above for the CoffeeScript engine.

### Minifying Assets

Several JavaScript and CSS minifiers are available through shorthand.

In Rails you will specify them with:

```ruby
config.assets.js_compressor  = :terser
config.assets.css_compressor = :scss
```

If you're not using Rails, configure this directly on the "environment".

``` ruby
environment.js_compressor  = :terser
environment.css_compressor = :scss
```

If you are using Sprockets directly with a Rack app, don't forget to add
the `terser` and `sass` gems to your Gemfile when using above options.

### Gzip

By default when Sprockets generates a compiled asset file it will also produce a gzipped copy of that file. Sprockets only gzips non-binary files such as CSS, javascript, and SVG files.

For example if Sprockets is generating

```
application-12345.css
```

Then it will also generate a compressed copy in

```
application-12345.css.gz
```

This behavior can be disabled, refer to your framework specific documentation.

### Serving Assets

In production you should generate your assets to a directory on disk and serve them either via Nginx or a feature like Rail's `config.public_file_server.enabled = true`.

On Rails you can generate assets by running:

```term
$ RAILS_ENV=production rake assets:precompile
```

In development Rails will serve assets from `Sprockets::Server`.

## Contributing to Sprockets

Sprockets is the work of hundreds of contributors. You're encouraged to submit pull requests, propose
features and discuss issues.

See [CONTRIBUTING](CONTRIBUTING.md).

### Version History

Please see the [CHANGELOG](https://github.com/rails/sprockets/tree/master/CHANGELOG.md)

## License
Sprockets is released under the [MIT License](MIT-LICENSE).
