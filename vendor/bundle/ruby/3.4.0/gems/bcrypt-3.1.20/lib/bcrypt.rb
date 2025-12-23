# A Ruby library implementing OpenBSD's bcrypt()/crypt_blowfish algorithm for
# hashing passwords.
module BCrypt
end

if RUBY_PLATFORM == "java"
  require 'java'
else
  require "openssl"
end

require "bcrypt_ext"

require 'bcrypt/error'
require 'bcrypt/engine'
require 'bcrypt/password'
