# -*- ruby -*-

require 'pathname'

module Pg

	VERSION = '0.8.0'

	gemdir = Pathname( __FILE__ ).dirname.parent.parent
	readme = gemdir + 'README.txt'

	header, message = readme.read.split( /^== Description/m )
	abort( message.strip )

end

