require 'active_support/core_ext/string/inflections'  # For #model_class constantize
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/object/try'          # For #find
require 'active_support/core_ext/module/delegation'
require 'global_id/uri/gid'

class GlobalID
  class << self
    attr_reader :app

    def create(model, options = {})
      if app = options.fetch(:app) { GlobalID.app }
        params = options.except(:app, :verifier, :for)
        new URI::GID.create(app, model, params), options
      else
        raise ArgumentError, 'An app is required to create a GlobalID. ' \
          'Pass the :app option or set the default GlobalID.app.'
      end
    end

    def find(gid, options = {})
      parse(gid, options).try(:find, options)
    end

    def parse(gid, options = {})
      gid.is_a?(self) ? gid : new(gid, options)
    rescue URI::Error
      parse_encoded_gid(gid, options)
    end

    def app=(app)
      @app = URI::GID.validate_app(app)
    end

    private
      def parse_encoded_gid(gid, options)
        new(Base64.urlsafe_decode64(gid), options) rescue nil
      end
  end

  attr_reader :uri
  delegate :app, :model_name, :model_id, :params, :to_s, :deconstruct_keys, to: :uri

  def initialize(gid, options = {})
    @uri = gid.is_a?(URI::GID) ? gid : URI::GID.parse(gid)
  end

  def find(options = {})
    Locator.locate self, options
  end

  def model_class
    @model_class ||= begin
      model = model_name.constantize

      if model <= GlobalID
        raise ArgumentError, "GlobalID and SignedGlobalID cannot be used as model_class."
      end
      model
    end
  end

  def ==(other)
    other.is_a?(GlobalID) && @uri == other.uri
  end
  alias_method :eql?, :==

  def hash
    self.class.hash | @uri.hash
  end

  def to_param
    Base64.urlsafe_encode64(to_s, padding: false)
  end

  def as_json(*)
    to_s
  end
end
