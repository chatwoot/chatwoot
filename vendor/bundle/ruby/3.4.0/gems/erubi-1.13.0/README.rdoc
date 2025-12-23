= Erubi

Erubi is a ERB template engine for ruby. It is a simplified fork of Erubis, using
the same basic algorithm, with the following differences:

* Handles postfix conditionals when using escaping (e.g. <tt><%= foo if bar %></tt>)
* Supports frozen_string_literal: true in templates via :freeze option
* Works with ruby's <tt>--enable-frozen-string-literal</tt> option
* Automatically freezes strings for template text when ruby optimizes it (on ruby 2.1+)
* Escapes <tt>'</tt> (apostrophe) when escaping for better XSS protection 
* Has 15x-6x faster escaping by using erb/escape or cgi/escape
* Has 81% smaller memory footprint (calculated using +ObjectSpace.memsize_of_all+)
* Does no monkey patching (Erubis adds a method to Kernel)
* Uses an immutable design (all options passed to the constructor, which returns a frozen object)
* Has simpler internals (1 file, <150 lines of code)
* Is not dead (Erubis hasn't been updated since 2011)

It is not designed with Erubis API compatibility in mind, though most Erubis
ERB syntax works, with the following exceptions:

* No support for <tt><%===</tt> for debug output

= Installation

  gem install erubi

= Source Code

Source code is available on GitHub at https://github.com/jeremyevans/erubi

= Usage

Erubi only has built in support for retrieving the generated source for a
file:

  require 'erubi'
  eval(Erubi::Engine.new(File.read('filename.erb')).src)

Most users will probably use Erubi via Rails or Tilt.  Erubi is the default
erb template handler in Tilt 2.0.6+ and Rails 5.1+.

== Capturing

Erubi does not support capturing block output into the template by default.
It currently ships with two implementations that allow it.

=== Erubi::CaptureBlockEngine

The recommended implementation can be required via +erubi/capture_block+,
which allows capturing to work with normal <tt><%=</tt> and <tt><%==</tt>
tags.

  <%= form do %>
    <input>
  <% end %>

When using the capture_block support, capture methods should just return
the text it emit into the template, and call +capture+ on the buffer value.
Since the buffer variable is a local variable and not an instance variable
by default, you'll probably want to set the +:bufvar+ variable when using
the capture_block support to an instance variable, and have any methods
used call capture on that instance variable.  Example:

  def form(&block)
    "<form>#{@_buf.capture(&block)}</form>"
  end

  puts eval(Erubi::CaptureBlockEngine.new(<<-END, bufvar: '@_buf', trim: false).src)
  before
  <%= form do %>
  inside
  <% end %>
  after
  END

  # Output:
  # before
  # <form>
  # inside
  # </form>
  # after

To use the capture_block support with tilt:

  require 'tilt'
  require 'erubi/capture_block'
  Tilt.new("filename.erb", :engine_class=>Erubi::CaptureBlockEngine).render

Note that the capture_block support, while very compatible with the default
support, is not 100% compatible.  One area where behavior differs is when
using multiple statements inside <tt><%=</tt> and <tt><%==</tt> tags:

  <%= 1; 2 %>

The default support will output 2, but the capture_block support will output
1.

=== Erubi::CaptureEndEngine

An alternative capture implementation can be required via +erubi/capture_end+,
which supports it via <tt><%|=</tt> and <tt><%|==</tt> tags which are
closed with a <tt><%|</tt> tag:

  <%|= form do %>
    <input>
  <%| end %>

It is only recommended to use +erubi/capture_end+ for backwards
compatibilty.

When using the capture_end support, capture methods (such as +form+ in the example
above) should return the (potentially modified) buffer. Similar to the
capture_block support, using an instance variable is recommended. Example:

  def form
    @_buf << "<form>"
    yield
    @_buf << "</form>"
    @_buf
  end

  puts eval(Erubi::CaptureEndEngine.new(<<-END, bufvar: '@_buf').src)
  before
  <%|= form do %>
  inside
  <%| end %>
  after
  END

  # Output:
  # before
  # <form>
  # inside
  # </form>
  # after

Alternatively, passing the option <tt>:yield_returns_buffer => true</tt> will return the
buffer captured by the block instead of the last expression in the block.

= Reporting Bugs

The bug tracker is located at https://github.com/jeremyevans/erubi/issues

= License

MIT

= Authors

Jeremy Evans <code@jeremyevans.net>
kuwata-lab.com
