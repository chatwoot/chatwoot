= net-http-persistent

home :: https://github.com/drbrain/net-http-persistent
rdoc :: https://rdoc.info/gems/net-http-persistent

== DESCRIPTION:

Manages persistent connections using Net::HTTP including a thread pool for
connecting to multiple hosts.

Using persistent HTTP connections can dramatically increase the speed of HTTP.
Creating a new HTTP connection for every request involves an extra TCP
round-trip and causes TCP congestion avoidance negotiation to start over.

Net::HTTP supports persistent connections with some API methods but does not
make setting up a single persistent connection or managing multiple
connections easy.  Net::HTTP::Persistent wraps Net::HTTP and allows you to
focus on how to make HTTP requests.

== FEATURES/PROBLEMS:

* Supports TLS with secure defaults
* Thread-safe
* Pure ruby

== SYNOPSIS

The following example will make two requests to the same server.  The
connection is kept alive between requests:

    require 'net/http/persistent'

    uri = URI 'http://example.com/awesome/web/service'

    http = Net::HTTP::Persistent.new name: 'my_app_name'

    # perform a GET
    response = http.request uri

    # create a POST
    post_uri = uri + 'create'
    post = Net::HTTP::Post.new post_uri.path
    post.set_form_data 'some' => 'cool data'

    # perform the POST, the URI is always required
    response = http.request post_uri, post

    # if you are done making http requests, or won't make requests for several
    # minutes
    http.shutdown

Please see the documentation on Net::HTTP::Persistent for more information,
including SSL connection verification, header handling and tunable options.

== INSTALL:

  gem install net-http-persistent

== LICENSE:

(The MIT License)

Copyright (c) Eric Hodel, Aaron Patterson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
