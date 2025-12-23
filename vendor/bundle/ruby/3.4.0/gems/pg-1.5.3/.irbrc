#!/usr/bin/ruby -*- ruby -*-

BEGIN {
	require 'pathname'
	require 'rbconfig'

	basedir = Pathname.new( __FILE__ ).dirname.expand_path
	libdir = basedir + "lib"

	puts ">>> Adding #{libdir} to load path..."
	$LOAD_PATH.unshift( libdir.to_s )
}


# Try to require the 'pg' library
begin
	$stderr.puts "Loading pg..."
	require 'pg'
rescue => e
	$stderr.puts "Ack! pg library failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end

