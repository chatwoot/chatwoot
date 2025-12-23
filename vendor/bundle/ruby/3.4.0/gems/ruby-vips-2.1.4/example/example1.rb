#!/usr/bin/ruby

require "logger"
require "vips"

GLib.logger.level = Logger::DEBUG

Vips::Operation.new "black"

GC.start
Vips::Operation.print_all
