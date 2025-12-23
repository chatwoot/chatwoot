
SimpleCov.start do
	add_filter "/spec/"
end

if ENV['TRAVIS']
	require 'coveralls'
	Coveralls.wear!
end
