# -*- ruby -*-

PGHOST   = 'localhost'
PGDB     = 'test'
#SOCKHOST = 'github.com'
SOCKHOST = 'it-trac.laika.com'

# Load pg first, so the libssl.so that libpq is linked against is loaded.
require 'pg'
$stderr.puts "connecting to postgres://#{PGHOST}/#{PGDB}"
conn = PG.connect( PGHOST, :dbname => PGDB )

# Now load OpenSSL, which might be linked against a different libssl.
require 'socket'
require 'openssl'
$stderr.puts "Connecting to #{SOCKHOST}"
sock = TCPSocket.open( SOCKHOST, 443 )
ctx = OpenSSL::SSL::SSLContext.new
sock = OpenSSL::SSL::SSLSocket.new( sock, ctx )
sock.sync_close = true

# The moment of truth...
$stderr.puts "Attempting to connect..."
begin
	sock.connect
rescue Errno
	$stderr.puts "Got an error connecting, but no segfault."
else
	$stderr.puts "Nope, no segfault!"
end

