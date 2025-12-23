# Down

Down is a utility tool for streaming, flexible and safe downloading of remote
files. It can use [open-uri] + `Net::HTTP`, [http.rb], [HTTPX], or `wget` as
the backend HTTP library.

## Installation

```rb
gem "down", "~> 5.0"
```

## Downloading

The primary method is `Down.download`, which downloads the remote file into a
`Tempfile`:

```rb
require "down"

tempfile = Down.download("http://example.com/nature.jpg")
tempfile #=> #<Tempfile:/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/20150925-55456-z7vxqz.jpg>
```

### Metadata

The returned `Tempfile` has some additional attributes extracted from the
response data:

```rb
tempfile.content_type      #=> "text/plain"
tempfile.original_filename #=> "document.txt"
tempfile.charset           #=> "utf-8"
```

### Maximum size

When you're accepting URLs from an outside source, it's a good idea to limit
the filesize (because attackers want to give a lot of work to your servers).
Down allows you to pass a `:max_size` option:

```rb
Down.download("http://example.com/image.jpg", max_size: 5 * 1024 * 1024) # 5 MB
# Down::TooLarge: file is too large (max is 5MB)
```

What is the advantage over simply checking size after downloading? Well, Down
terminates the download very early, as soon as it gets the `Content-Length`
header. And if the `Content-Length` header is missing, Down will terminate the
download as soon as the downloaded content surpasses the maximum size.

### Destination

By default the remote file will be downloaded into a temporary location and
returned as a `Tempfile`. If you would like the file to be downloaded to a
specific location on disk, you can specify the `:destination` option:

```rb
Down.download("http://example.com/image.jpg", destination: "/path/to/destination")
#=> nil
```

In this case `Down.download` won't have any return value, so if you need a File
object you'll have to create it manually.

You can also keep the tempfile, but override the extension:

```rb
tempfile = Down.download("http://example.com/some/file", extension: "txt")
File.extname(tempfile.path) #=> ".txt"
```

### Basic authentication

`Down.download` and `Down.open` will automatically detect and apply HTTP basic
authentication from the URL:

```rb
Down.download("http://user:password@example.org")
Down.open("http://user:password@example.org")
```

### Progress

`Down.download` supports `:content_length_proc`, which gets called with the
value of the `Content-Length` header as soon as it's received, and
`:progress_proc`, which gets called with current filesize whenever a new chunk
is downloaded.

```rb
Down.download "http://example.com/movie.mp4",
  content_length_proc: -> (content_length) { ... },
  progress_proc:       -> (progress)       { ... }
```

## Streaming

Down has the ability to retrieve content of the remote file *as it is being
downloaded*. The `Down.open` method returns a `Down::ChunkedIO` object which
represents the remote file on the given URL. When you read from it, Down
internally downloads chunks of the remote file, but only how much is needed.

```rb
remote_file = Down.open("http://example.com/image.jpg")
remote_file.size # read from the "Content-Length" header

remote_file.read(1024) # downloads and returns first 1 KB
remote_file.read(1024) # downloads and returns next 1 KB

remote_file.eof? #=> false
remote_file.read # downloads and returns the rest of the file content
remote_file.eof? #=> true

remote_file.close # closes the HTTP connection and deletes the internal Tempfile
```

The following IO methods are implemented:

* `#read` & `#readpartial`
* `#gets`
* `#seek`
* `#pos` & `#tell`
* `#eof?`
* `#rewind`
* `#close`

### Caching

By default the downloaded content is internally cached into a `Tempfile`, so
that when you rewind the `Down::ChunkedIO`, it continues reading the cached
content that it had already retrieved.

```rb
remote_file = Down.open("http://example.com/image.jpg")
remote_file.read(1*1024*1024) # downloads, caches, and returns first 1MB
remote_file.rewind
remote_file.read(1*1024*1024) # reads the cached content
remote_file.read(1*1024*1024) # downloads the next 1MB
```

If you want to save on IO calls and on disk usage, and don't need to be able to
rewind the `Down::ChunkedIO`, you can disable caching downloaded content:

```rb
Down.open("http://example.com/image.jpg", rewindable: false)
```

### Yielding chunks

You can also yield chunks directly as they're downloaded via `#each_chunk`, in
which case the downloaded content is not cached into a file regardless of the
`:rewindable` option.

```rb
remote_file = Down.open("http://example.com/image.jpg")
remote_file.each_chunk { |chunk| ... }
remote_file.close
```

### Data

You can access the response status and headers of the HTTP request that was made:

```rb
remote_file = Down.open("http://example.com/image.jpg")
remote_file.data[:status]   #=> 200
remote_file.data[:headers]  #=> { "Content-Type" => "image/jpeg", ... } (header names are normalized)
remote_file.data[:response] # returns the response object
```

Note that a `Down::ResponseError` exception will automatically be raised if
response status was 4xx or 5xx.

### Down::ChunkedIO

The `Down.open` performs HTTP logic and returns an instance of
`Down::ChunkedIO`. However, `Down::ChunkedIO` is a generic class that can wrap
any kind of streaming. It accepts an `Enumerator` that yields chunks of
content, and provides IO-like interface over that enumerator, calling it
whenever more content is needed.

```rb
require "down/chunked_io"

Down::ChunkedIO.new(...)
```

* `:chunks` – `Enumerator` that yields chunks of content
* `:size` – size of the file if it's known (returned by `#size`)
* `:on_close` – called when streaming finishes or IO is closed
* `:data` - custom data that you want to store (returned by `#data`)
* `:rewindable` - whether to cache retrieved data into a file (defaults to `true`)
* `:encoding` - force content to be returned in specified encoding (defaults to `Encoding::BINARY`)

Here is an example of creating a streaming IO of a MongoDB GridFS file:

```rb
require "down/chunked_io"

mongo = Mongo::Client.new(...)
bucket = mongo.database.fs

content_length = bucket.find(_id: id).first[:length]
stream = bucket.open_download_stream(id)

io = Down::ChunkedIO.new(
  size: content_length,
  chunks: stream.enum_for(:each),
  on_close: -> { stream.close },
)
```

### Exceptions

Down tries to recognize various types of exceptions and re-raise them as one of
the `Down::Error` subclasses. This is Down's exception hierarchy:

* `Down::Error`
  * `Down::TooLarge`
  * `Down::InvalidUrl`
  * `Down::TooManyRedirects`
  * `Down::NotModified`
  * `Down::ResponseError`
    * `Down::ClientError`
      * `Down::NotFound`
    * `Down::ServerError`
  * `Down::ConnectionError`
  * `Down::TimeoutError`
  * `Down::SSLError`

## Backends

The following backends are available:

* [Down::NetHttp](#downnethttp) (default)
* [Down::Http](#downhttp)
* [Down::Httpx](#downhttpx)
* [Down::Wget](#downwget)

You can use the backend directly:

```rb
require "down/net_http"

Down::NetHttp.download("...")
Down::NetHttp.open("...")
```

Or you can set the backend globally (default is `:net_http`):

```rb
require "down"

Down.backend :http # use the Down::Http backend

Down.download("...")
Down.open("...")
```

### Down::NetHttp

The `Down::NetHttp` backend implements downloads using [open-uri] and
[Net::HTTP] standard libraries.

```rb
gem "down", "~> 5.0"
```
```rb
require "down/net_http"

tempfile = Down::NetHttp.download("http://nature.com/forest.jpg")
tempfile #=> #<Tempfile:/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/20150925-55456-z7vxqz.jpg>

io = Down::NetHttp.open("http://nature.com/forest.jpg")
io #=> #<Down::ChunkedIO ...>
```

`Down::NetHttp.download` is implemented as a wrapper around open-uri, and fixes
some of open-uri's undesired behaviours:

* uses `URI::HTTP#open` or `URI::HTTPS#open` directly for [security](https://sakurity.com/blog/2015/02/28/openuri.html)
* always returns a `Tempfile` object, whereas open-uri returns `StringIO`
  when file is smaller than 10KB
* gives the extension to the `Tempfile` object from the URL
* allows you to limit maximum number of redirects

On the other hand `Down::NetHttp.open` is implemented using Net::HTTP directly,
as open-uri doesn't support downloading on-demand.

#### Redirects

`Down::NetHttp#download` turns off open-uri's following redirects, as open-uri
doesn't have a way to limit the maximum number of hops, and implements its own.
By default maximum of 2 redirects will be followed, but you can change it via
the `:max_redirects` option:

```rb
Down::NetHttp.download("http://example.com/image.jpg")                   # 2 redirects allowed
Down::NetHttp.download("http://example.com/image.jpg", max_redirects: 5) # 5 redirects allowed
Down::NetHttp.download("http://example.com/image.jpg", max_redirects: 0) # 0 redirects allowed

Down::NetHttp.open("http://example.com/image.jpg")                       # 2 redirects allowed
Down::NetHttp.open("http://example.com/image.jpg", max_redirects: 5)     # 5 redirects allowed
Down::NetHttp.open("http://example.com/image.jpg", max_redirects: 0)     # 0 redirects allowed
```

#### Proxy

An HTTP proxy can be specified via the `:proxy` option:

```rb
Down::NetHttp.download("http://example.com/image.jpg", proxy: "http://proxy.org")
Down::NetHttp.open("http://example.com/image.jpg", proxy: "http://user:password@proxy.org")
```

#### Timeouts

Timeouts can be configured via the `:open_timeout` and `:read_timeout` options:

```rb
Down::NetHttp.download("http://example.com/image.jpg", open_timeout: 5)
Down::NetHttp.open("http://example.com/image.jpg", read_timeout: 10)
```

#### Headers

Request headers can be added via the `:headers` option:

```rb
Down::NetHttp.download("http://example.com/image.jpg", headers: { "Header" => "Value" })
Down::NetHttp.open("http://example.com/image.jpg", headers: { "Header" => "Value" })
```

#### SSL options

The `:ssl_ca_cert` and `:ssl_verify_mode` options are supported, and they have
the same semantics as in `open-uri`:

```rb
Down::NetHttp.open("http://example.com/image.jpg",
  ssl_ca_cert:     "/path/to/cert",
  ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER)
```

#### URI normalization

If the URL isn't parseable by `URI.parse`, `Down::NetHttp` will
attempt to normalize the URL using [Addressable::URI], URI-escaping
any potentially unescaped characters. You can change the normalizer
via the `:uri_normalizer` option:

```rb
# this skips URL normalization
Down::NetHttp.download("http://example.com/image.jpg", uri_normalizer: -> (url) { url })
```

#### Additional options

Any additional options passed to `Down.download` will be forwarded to
[open-uri], so you can for example add basic authentication or a timeout:

```rb
Down::NetHttp.download "http://example.com/image.jpg",
  http_basic_authentication: ['john', 'secret'],
  read_timeout: 5
```

You can also initialize the backend with default options:

```rb
net_http = Down::NetHttp.new(open_timeout: 3)

net_http.download("http://example.com/image.jpg")
net_http.open("http://example.com/image.jpg")
```

### Down::Http

The `Down::Http` backend implements downloads using the [http.rb] gem.

```rb
gem "down", "~> 5.0"
gem "http", "~> 5.0"
```
```rb
require "down/http"

tempfile = Down::Http.download("http://nature.com/forest.jpg")
tempfile #=> #<Tempfile:/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/20150925-55456-z7vxqz.jpg>

io = Down::Http.open("http://nature.com/forest.jpg")
io #=> #<Down::ChunkedIO ...>
```

Some features that give the http.rb backend an advantage over `open-uri` and
`Net::HTTP` include:

* Low memory usage (**10x less** than `open-uri`/`Net::HTTP`)
* Proper SSL support
* Support for persistent connections
* Global timeouts (limiting how long the whole request can take)
* Chainable builder API for setting default options

#### Additional options

All additional options will be forwarded to `HTTP::Client#request`:

```rb
Down::Http.download("http://example.org/image.jpg", headers: { "Foo" => "Bar" })
Down::Http.open("http://example.org/image.jpg", follow: { max_hops: 0 })
```

However, it's recommended to configure request options using http.rb's
chainable API, as it's more convenient than passing raw options.

```rb
Down::Http.open("http://example.org/image.jpg") do |client|
  client.timeout(connect: 3, read: 3)
end
```

You can also initialize the backend with default options:

```rb
http = Down::Http.new(headers: { "Foo" => "Bar" })
# or
http = Down::Http.new { |client| client.timeout(connect: 3) }

http.download("http://example.com/image.jpg")
http.open("http://example.com/image.jpg")
```

#### Request method

By default `Down::Http` makes a `GET` request to the specified endpoint, but you
can specify a different request method using the `:method` option:

```rb
Down::Http.download("http://example.org/image.jpg", method: :post)
Down::Http.open("http://example.org/image.jpg", method: :post)

down = Down::Http.new(method: :post)
down.download("http://example.org/image.jpg")
```

### Down::Httpx

The `Down::Httpx` backend implements downloads using the [HTTPX] gem, which
supports the HTTP/2 protocol, in addition to many other features.

```rb
gem "down", "~> 5.0"
gem "httpx", "~> 0.22"
```
```rb
require "down/httpx"

tempfile = Down::Httpx.download("http://nature.com/forest.jpg")
tempfile #=> #<Tempfile:/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/20150925-55456-z7vxqz.jpg>

io = Down::Httpx.open("http://nature.com/forest.jpg")
io #=> #<Down::ChunkedIO ...>
```

It's implemented in much of the same way as `Down::Http`, so be sure to check
its docs for ways to pass additional options.

### Down::Wget (experimental)

The `Down::Wget` backend implements downloads using the `wget` command line
utility.

```rb
gem "down", "~> 5.0"
gem "posix-spawn" # omit if on JRuby
gem "http_parser.rb"
```
```rb
require "down/wget"

tempfile = Down::Wget.download("http://nature.com/forest.jpg")
tempfile #=> #<Tempfile:/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/20150925-55456-z7vxqz.jpg>

io = Down::Wget.open("http://nature.com/forest.jpg")
io #=> #<Down::ChunkedIO ...>
```

One major advantage of `wget` is that it automatically resumes downloads that
were interrupted due to network failures, which is very useful when you're
downloading large files.

However, the Wget backend should still be considered experimental, as it wasn't
easy to implement a CLI wrapper that streams output, so it's possible that I've
made mistakes. Let me know how it's working out for you 😉.

#### Additional arguments

You can pass additional arguments to the underlying `wget` commmand via symbols:

```rb
Down::Wget.download("http://nature.com/forest.jpg", :no_proxy, connect_timeout: 3)
Down::Wget.open("http://nature.com/forest.jpg", user: "janko", password: "secret")
```

You can also initialize the backend with default arguments:

```rb
wget = Down::Wget.new(:no_proxy, connect_timeout: 3)

wget.download("http://nature.com/forest.jpg")
wget.open("http://nature.com/forest.jpg")
```

## Supported Ruby versions

* MRI 2.3
* MRI 2.4
* MRI 2.5
* MRI 2.6
* MRI 2.7
* MRI 3.0
* MRI 3.1
* JRuby 9.3

## Development

Tests require that a [httpbin] server is running locally, which you can do via Docker:

```sh
$ docker pull kennethreitz/httpbin
$ docker run -p 80:80 kennethreitz/httpbin
```

Then you can run tests:

```
$ bundle exec rake test
```

## License

[MIT](LICENSE.txt)

[open-uri]: http://ruby-doc.org/stdlib-2.3.0/libdoc/open-uri/rdoc/OpenURI.html
[Net::HTTP]: https://ruby-doc.org/stdlib-2.4.1/libdoc/net/http/rdoc/Net/HTTP.html
[http.rb]: https://github.com/httprb/http
[HTTPX]: https://github.com/HoneyryderChuck/httpx
[Addressable::URI]: https://github.com/sporkmonger/addressable
[httpbin]: https://github.com/postmanlabs/httpbin
