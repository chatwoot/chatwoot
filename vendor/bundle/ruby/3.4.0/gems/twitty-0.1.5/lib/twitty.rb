require 'oauth'
require 'json'

require 'twitty/version'
require 'twitty/constants'
require 'twitty/config'
require 'twitty/payload'
require 'twitty/request'
require 'twitty/response'
require 'twitty/errors'
require 'twitty/facade'

class Twitty::Error < StandardError
  # Your code goes here...
end
