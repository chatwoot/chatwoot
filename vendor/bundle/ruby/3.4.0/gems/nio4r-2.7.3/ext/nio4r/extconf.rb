# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2011-2020, by Tony Arcieri.
# Copyright, 2014, by Hiroshi Shibata.
# Copyright, 2014, by Sergey Avseyev.
# Copyright, 2015, by Daniel Berger.
# Copyright, 2017, by Jun Aruga.
# Copyright, 2017, by Usaku Nakamura.
# Copyright, 2017, by Lars Kanis.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2020, by Gregory Longtin.
# Copyright, 2020, by Boaz Segev.
# Copyright, 2020, by Joao Fernandes.
# Copyright, 2021, by Jeffrey Martin.

require "rubygems"

# Write a dummy Makefile on Windows because we use the pure Ruby implementation there
if Gem.win_platform?
  begin
    require "devkit" if RUBY_PLATFORM.include?("mingw")
  rescue LoadError => e
  end
  File.write("Makefile", "all install::\n")
  File.write("nio4r_ext.so", "")
  exit
end

require "mkmf"

have_header("unistd.h")
have_func("rb_io_descriptor")

$defs << "-DEV_USE_LINUXAIO"     if have_header("linux/aio_abi.h")
$defs << "-DEV_USE_IOURING"      if have_header("linux/io_uring.h")
$defs << "-DEV_USE_SELECT"       if have_header("sys/select.h")
$defs << "-DEV_USE_POLL"         if have_type("port_event_t", "poll.h")
$defs << "-DEV_USE_EPOLL"        if have_header("sys/epoll.h")
$defs << "-DEV_USE_KQUEUE"       if have_header("sys/event.h") && have_header("sys/queue.h")
$defs << "-DEV_USE_PORT"         if have_type("port_event_t", "port.h")
$defs << "-DHAVE_SYS_RESOURCE_H" if have_header("sys/resource.h")

$defs << "-DEV_STANDALONE" # prevent libev from assuming "config.h" exists

CONFIG["optflags"] << " -fno-strict-aliasing" unless RUBY_PLATFORM =~ /mswin/

if RUBY_PLATFORM =~ /darwin/
  $DLDFLAGS.gsub!(/\-arch\s+[^\s]+/, "")
end

dir_config "nio4r_ext"
create_makefile "nio4r_ext"
