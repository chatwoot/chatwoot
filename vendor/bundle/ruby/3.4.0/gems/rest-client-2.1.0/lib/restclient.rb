require 'net/http'
require 'openssl'
require 'stringio'
require 'uri'

require File.dirname(__FILE__) + '/restclient/version'
require File.dirname(__FILE__) + '/restclient/platform'
require File.dirname(__FILE__) + '/restclient/exceptions'
require File.dirname(__FILE__) + '/restclient/utils'
require File.dirname(__FILE__) + '/restclient/request'
require File.dirname(__FILE__) + '/restclient/abstract_response'
require File.dirname(__FILE__) + '/restclient/response'
require File.dirname(__FILE__) + '/restclient/raw_response'
require File.dirname(__FILE__) + '/restclient/resource'
require File.dirname(__FILE__) + '/restclient/params_array'
require File.dirname(__FILE__) + '/restclient/payload'
require File.dirname(__FILE__) + '/restclient/windows'

# This module's static methods are the entry point for using the REST client.
#
#   # GET
#   xml = RestClient.get 'http://example.com/resource'
#   jpg = RestClient.get 'http://example.com/resource', :accept => 'image/jpg'
#
#   # authentication and SSL
#   RestClient.get 'https://user:password@example.com/private/resource'
#
#   # POST or PUT with a hash sends parameters as a urlencoded form body
#   RestClient.post 'http://example.com/resource', :param1 => 'one'
#
#   # nest hash parameters
#   RestClient.post 'http://example.com/resource', :nested => { :param1 => 'one' }
#
#   # POST and PUT with raw payloads
#   RestClient.post 'http://example.com/resource', 'the post body', :content_type => 'text/plain'
#   RestClient.post 'http://example.com/resource.xml', xml_doc
#   RestClient.put 'http://example.com/resource.pdf', File.read('my.pdf'), :content_type => 'application/pdf'
#
#   # DELETE
#   RestClient.delete 'http://example.com/resource'
#
#   # retreive the response http code and headers
#   res = RestClient.get 'http://example.com/some.jpg'
#   res.code                    # => 200
#   res.headers[:content_type]  # => 'image/jpg'
#
#   # HEAD
#   RestClient.head('http://example.com').headers
#
# To use with a proxy, just set RestClient.proxy to the proper http proxy:
#
#   RestClient.proxy = "http://proxy.example.com/"
#
# Or inherit the proxy from the environment:
#
#   RestClient.proxy = ENV['http_proxy']
#
# For live tests of RestClient, try using http://rest-test.heroku.com, which echoes back information about the rest call:
#
#   >> RestClient.put 'http://rest-test.heroku.com/resource', :foo => 'baz'
#   => "PUT http://rest-test.heroku.com/resource with a 7 byte payload, content type application/x-www-form-urlencoded {\"foo\"=>\"baz\"}"
#
module RestClient

  def self.get(url, headers={}, &block)
    Request.execute(:method => :get, :url => url, :headers => headers, &block)
  end

  def self.post(url, payload, headers={}, &block)
    Request.execute(:method => :post, :url => url, :payload => payload, :headers => headers, &block)
  end

  def self.patch(url, payload, headers={}, &block)
    Request.execute(:method => :patch, :url => url, :payload => payload, :headers => headers, &block)
  end

  def self.put(url, payload, headers={}, &block)
    Request.execute(:method => :put, :url => url, :payload => payload, :headers => headers, &block)
  end

  def self.delete(url, headers={}, &block)
    Request.execute(:method => :delete, :url => url, :headers => headers, &block)
  end

  def self.head(url, headers={}, &block)
    Request.execute(:method => :head, :url => url, :headers => headers, &block)
  end

  def self.options(url, headers={}, &block)
    Request.execute(:method => :options, :url => url, :headers => headers, &block)
  end

  # A global proxy URL to use for all requests. This can be overridden on a
  # per-request basis by passing `:proxy` to RestClient::Request.
  def self.proxy
    @proxy ||= nil
  end

  def self.proxy=(value)
    @proxy = value
    @proxy_set = true
  end

  # Return whether RestClient.proxy was set explicitly. We use this to
  # differentiate between no value being set and a value explicitly set to nil.
  #
  # @return [Boolean]
  #
  def self.proxy_set?
    @proxy_set ||= false
  end

  # Setup the log for RestClient calls.
  # Value should be a logger but can can be stdout, stderr, or a filename.
  # You can also configure logging by the environment variable RESTCLIENT_LOG.
  def self.log= log
    @@log = create_log log
  end

  # Create a log that respond to << like a logger
  # param can be 'stdout', 'stderr', a string (then we will log to that file) or a logger (then we return it)
  def self.create_log param
    if param
      if param.is_a? String
        if param == 'stdout'
          stdout_logger = Class.new do
            def << obj
              STDOUT.puts obj
            end
          end
          stdout_logger.new
        elsif param == 'stderr'
          stderr_logger = Class.new do
            def << obj
              STDERR.puts obj
            end
          end
          stderr_logger.new
        else
          file_logger = Class.new do
            attr_writer :target_file

            def << obj
              File.open(@target_file, 'a') { |f| f.puts obj }
            end
          end
          logger = file_logger.new
          logger.target_file = param
          logger
        end
      else
        param
      end
    end
  end

  @@env_log = create_log ENV['RESTCLIENT_LOG']

  @@log = nil

  def self.log # :nodoc:
    @@env_log || @@log
  end

  @@before_execution_procs = []

  # Add a Proc to be called before each request in executed.
  # The proc parameters will be the http request and the request params.
  def self.add_before_execution_proc &proc
    raise ArgumentError.new('block is required') unless proc
    @@before_execution_procs << proc
  end

  # Reset the procs to be called before each request is executed.
  def self.reset_before_execution_procs
    @@before_execution_procs = []
  end

  def self.before_execution_procs # :nodoc:
    @@before_execution_procs
  end

end
