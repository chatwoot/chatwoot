# frozen_string_literal: true

require_relative "config/attr_accessors"
require_relative "config/attr_inheritance"
require_relative "config/attr_type_coercion"

module Net
  class IMAP

    # Net::IMAP::Config <em>(available since +v0.4.13+)</em> stores
    # configuration options for Net::IMAP clients.  The global configuration can
    # be seen at either Net::IMAP.config or Net::IMAP::Config.global, and the
    # client-specific configuration can be seen at Net::IMAP#config.
    #
    # When creating a new client, all unhandled keyword arguments to
    # Net::IMAP.new are delegated to Config.new.  Every client has its own
    # config.
    #
    #   debug_client = Net::IMAP.new(hostname, debug: true)
    #   quiet_client = Net::IMAP.new(hostname, debug: false)
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    # == Inheritance
    #
    # Configs have a parent[rdoc-ref:Config::AttrInheritance#parent] config, and
    # any attributes which have not been set locally will inherit the parent's
    # value.  Every client creates its own specific config.  By default, client
    # configs inherit from Config.global.
    #
    #   plain_client = Net::IMAP.new(hostname)
    #   debug_client = Net::IMAP.new(hostname, debug: true)
    #   quiet_client = Net::IMAP.new(hostname, debug: false)
    #
    #   plain_client.config.inherited?(:debug)  # => true
    #   debug_client.config.inherited?(:debug)  # => false
    #   quiet_client.config.inherited?(:debug)  # => false
    #
    #   plain_client.config.debug?  # => false
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    #   # Net::IMAP.debug is delegated to Net::IMAP::Config.global.debug
    #   Net::IMAP.debug = true
    #   plain_client.config.debug?  # => true
    #   debug_client.config.debug?  # => true
    #   quiet_client.config.debug?  # => false
    #
    #   Net::IMAP.debug = false
    #   plain_client.config.debug = true
    #   plain_client.config.inherited?(:debug)  # => false
    #   plain_client.config.debug?  # => true
    #   plain_client.config.reset(:debug)
    #   plain_client.config.inherited?(:debug)  # => true
    #   plain_client.config.debug?  # => false
    #
    # == Versioned defaults
    #
    # The effective default configuration for a specific +x.y+ version of
    # +net-imap+ can be loaded with the +config+ keyword argument to
    # Net::IMAP.new.  Requesting default configurations for previous versions
    # enables extra backward compatibility with those versions:
    #
    #   client = Net::IMAP.new(hostname, config: 0.3)
    #   client.config.sasl_ir                  # => false
    #   client.config.responses_without_block  # => :silence_deprecation_warning
    #
    #   client = Net::IMAP.new(hostname, config: 0.4)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :silence_deprecation_warning
    #
    #   client = Net::IMAP.new(hostname, config: 0.5)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :warn
    #
    #   client = Net::IMAP.new(hostname, config: :future)
    #   client.config.sasl_ir                  # => true
    #   client.config.responses_without_block  # => :raise
    #
    # The versioned default configs inherit certain specific config options from
    # Config.global, for example #debug:
    #
    #   client = Net::IMAP.new(hostname, config: 0.4)
    #   Net::IMAP.debug = false
    #   client.config.debug?  # => false
    #
    #   Net::IMAP.debug = true
    #   client.config.debug?  # => true
    #
    # Use #load_defaults to globally behave like a specific version:
    #   client = Net::IMAP.new(hostname)
    #   client.config.sasl_ir              # => true
    #   Net::IMAP.config.load_defaults 0.3
    #   client.config.sasl_ir              # => false
    #
    # === Named defaults
    # In addition to +x.y+ version numbers, the following aliases are supported:
    #
    # [+:default+]
    #   An alias for +:current+.
    #
    #   >>>
    #   *NOTE*: This is _not_ the same as Config.default.  It inherits some
    #   attributes from Config.global, for example: #debug.
    # [+:current+]
    #   An alias for the current +x.y+ version's defaults.
    # [+:next+]
    #   The _planned_ config for the next +x.y+ version.
    # [+:future+]
    #   The _planned_ eventual config for some future +x.y+ version.
    #
    # For example, to raise exceptions for all current deprecations:
    #   client = Net::IMAP.new(hostname, config: :future)
    #   client.responses  # raises an ArgumentError
    #
    # == Thread Safety
    #
    # *NOTE:* Updates to config objects are not synchronized for thread-safety.
    #
    class Config
      # Array of attribute names that are _not_ loaded by #load_defaults.
      DEFAULT_TO_INHERIT = %i[debug].freeze
      private_constant :DEFAULT_TO_INHERIT

      # The default config, which is hardcoded and frozen.
      def self.default; @default end

      # The global config object.  Also available from Net::IMAP.config.
      def self.global; @global if defined?(@global) end

      # A hash of hard-coded configurations, indexed by version number or name.
      # Values can be accessed with any object that responds to +to_sym+ or
      # +to_r+/+to_f+ with a non-zero number.
      #
      # Config::[] gets named or numbered versions from this hash.
      #
      # For example:
      #     Net::IMAP::Config.version_defaults[0.5] == Net::IMAP::Config[0.5]
      #     Net::IMAP::Config[0.5]       == Net::IMAP::Config[0.5r]     # => true
      #     Net::IMAP::Config["current"] == Net::IMAP::Config[:current] # => true
      #     Net::IMAP::Config["0.5.6"]   == Net::IMAP::Config[0.5r]     # => true
      def self.version_defaults; @version_defaults end
      @version_defaults = Hash.new {|h, k|
        # NOTE: String responds to both so the order is significant.
        # And ignore non-numeric conversion to zero, because: "wat!?".to_r == 0
        (h.fetch(k.to_r, nil) || h.fetch(k.to_f, nil) if k.is_a?(Numeric)) ||
          (h.fetch(k.to_sym, nil) if k.respond_to?(:to_sym)) ||
          (h.fetch(k.to_r,   nil) if k.respond_to?(:to_r) && k.to_r != 0r) ||
          (h.fetch(k.to_f,   nil) if k.respond_to?(:to_f) && k.to_f != 0.0)
      }

      # :call-seq:
      #  Net::IMAP::Config[number] -> versioned config
      #  Net::IMAP::Config[symbol] -> named config
      #  Net::IMAP::Config[hash]   -> new frozen config
      #  Net::IMAP::Config[config] -> same config
      #
      # Given a version number, returns the default configuration for the target
      # version.  See Config@Versioned+defaults.
      #
      # Given a version name, returns the default configuration for the target
      # version.  See Config@Named+defaults.
      #
      # Given a Hash, creates a new _frozen_ config which inherits from
      # Config.global.  Use Config.new for an unfrozen config.
      #
      # Given a config, returns that same config.
      def self.[](config)
        if    config.is_a?(Config)         then config
        elsif config.nil? && global.nil?   then nil
        elsif config.respond_to?(:to_hash) then new(global, **config).freeze
        else
          version_defaults[config] or
            case config
            when Numeric
              raise RangeError, "unknown config version: %p" % [config]
            when String, Symbol
              raise KeyError, "unknown config name: %p" % [config]
            else
              raise TypeError, "no implicit conversion of %s to %s" % [
                config.class, Config
              ]
            end
        end
      end

      include AttrAccessors
      include AttrInheritance
      include AttrTypeCoercion

      # The debug mode (boolean).  The default value is +false+.
      #
      # When #debug is +true+:
      # * Data sent to and received from the server will be logged.
      # * ResponseParser will print warnings with extra detail for parse
      #   errors.  _This may include recoverable errors._
      # * ResponseParser makes extra assertions.
      #
      # *NOTE:* Versioned default configs inherit #debug from Config.global, and
      # #load_defaults will not override #debug.
      attr_accessor :debug, type: :boolean

      # method: debug?
      # :call-seq: debug? -> boolean
      #
      # Alias for #debug

      # Seconds to wait until a connection is opened.
      #
      # Applied separately for establishing TCP connection and starting a TLS
      # connection.
      #
      # If the IMAP object cannot open a connection within this time,
      # it raises a Net::OpenTimeout exception.
      #
      # See Net::IMAP.new and Net::IMAP#starttls.
      #
      # The default value is +30+ seconds.
      attr_accessor :open_timeout, type: Integer

      # Seconds to wait until an IDLE response is received, after
      # the client asks to leave the IDLE state.
      #
      # See Net::IMAP#idle and Net::IMAP#idle_done.
      #
      # The default value is +5+ seconds.
      attr_accessor :idle_response_timeout, type: Integer

      # Whether to use the +SASL-IR+ extension when the server and \SASL
      # mechanism both support it.  Can be overridden by the +sasl_ir+ keyword
      # parameter to Net::IMAP#authenticate.
      #
      # <em>(Support for +SASL-IR+ was added in +v0.4.0+.)</em>
      #
      # ==== Valid options
      #
      # [+false+ <em>(original behavior, before support was added)</em>]
      #   Do not use +SASL-IR+, even when it is supported by the server and the
      #   mechanism.
      #
      # [+true+ <em>(default since +v0.4+)</em>]
      #   Use +SASL-IR+ when it is supported by the server and the mechanism.
      attr_accessor :sasl_ir, type: :boolean

      # The maximum allowed server response size.  When +nil+, there is no limit
      # on response size.
      #
      # The default value (512 MiB, since +v0.5.7+) is <em>very high</em> and
      # unlikely to be reached.  To use a lower limit, fetch message bodies in
      # chunks rather than all at once.  A _much_ lower value should be used
      # with untrusted servers (for example, when connecting to a user-provided
      # hostname).
      #
      # <em>Please Note:</em> this only limits the size per response.  It does
      # not prevent a flood of individual responses and it does not limit how
      # many unhandled responses may be stored on the responses hash.  See
      # Net::IMAP@Unbounded+memory+use.
      #
      # Socket reads are limited to the maximum remaining bytes for the current
      # response: max_response_size minus the bytes that have already been read.
      # When the limit is reached, or reading a +literal+ _would_ go over the
      # limit, ResponseTooLargeError is raised and the connection is closed.
      # See also #socket_read_limit.
      #
      # Note that changes will not take effect immediately, because the receiver
      # thread may already be waiting for the next response using the previous
      # value.  Net::IMAP#noop can force a response and enforce the new setting
      # immediately.
      #
      # ==== Versioned Defaults
      #
      # Net::IMAP#max_response_size <em>was added in +v0.2.5+ and +v0.3.9+ as an
      # attr_accessor, and in +v0.4.20+ and +v0.5.7+ as a delegator to this
      # config attribute.</em>
      #
      # * original: +nil+ <em>(no limit)</em>
      # * +0.5+: 512 MiB
      attr_accessor :max_response_size, type: Integer?

      # Controls the behavior of Net::IMAP#responses when called without any
      # arguments (+type+ or +block+).
      #
      # ==== Valid options
      #
      # [+:silence_deprecation_warning+ <em>(original behavior)</em>]
      #   Returns the mutable responses hash (without any warnings).
      #   <em>This is not thread-safe.</em>
      #
      # [+:warn+ <em>(default since +v0.5+)</em>]
      #   Prints a warning and returns the mutable responses hash.
      #   <em>This is not thread-safe.</em>
      #
      # [+:frozen_dup+ <em>(planned default for +v0.6+)</em>]
      #   Returns a frozen copy of the unhandled responses hash, with frozen
      #   array values.
      #
      #   Note that calling IMAP#responses with a +type+ and without a block is
      #   not configurable and always behaves like +:frozen_dup+.
      #
      #   <em>(+:frozen_dup+ config option was added in +v0.4.17+)</em>
      #
      # [+:raise+]
      #   Raise an ArgumentError with the deprecation warning.
      #
      # Note: #responses_without_args is an alias for #responses_without_block.
      attr_accessor :responses_without_block, type: Enum[
        :silence_deprecation_warning, :warn, :frozen_dup, :raise,
      ]

      alias responses_without_args  responses_without_block  # :nodoc:
      alias responses_without_args= responses_without_block= # :nodoc:

      ##
      # :attr_accessor: responses_without_args
      #
      # Alias for responses_without_block

      # Whether ResponseParser should use the deprecated UIDPlusData or
      # CopyUIDData for +COPYUID+ response codes, and UIDPlusData or
      # AppendUIDData for +APPENDUID+ response codes.
      #
      # UIDPlusData stores its data in arrays of numbers, which is vulnerable to
      # a memory exhaustion denial of service attack from an untrusted or
      # compromised server.  Set this option to +false+ to completely block this
      # vulnerability.  Otherwise, parser_max_deprecated_uidplus_data_size
      # mitigates this vulnerability.
      #
      # AppendUIDData and CopyUIDData are _mostly_ backward-compatible with
      # UIDPlusData.  Most applications should be able to upgrade with little
      # or no changes.
      #
      # <em>(Parser support for +UIDPLUS+ added in +v0.3.2+.)</em>
      #
      # <em>(Config option added in +v0.4.19+ and +v0.5.6+.)</em>
      #
      # <em>UIDPlusData will be removed in +v0.6+ and this config setting will
      # be ignored.</em>
      #
      # ==== Valid options
      #
      # [+true+ <em>(original default)</em>]
      #    ResponseParser only uses UIDPlusData.
      #
      # [+:up_to_max_size+ <em>(default since +v0.5.6+)</em>]
      #    ResponseParser uses UIDPlusData when the +uid-set+ size is below
      #    parser_max_deprecated_uidplus_data_size.  Above that size,
      #    ResponseParser uses AppendUIDData or CopyUIDData.
      #
      # [+false+ <em>(planned default for +v0.6+)</em>]
      #    ResponseParser _only_ uses AppendUIDData and CopyUIDData.
      attr_accessor :parser_use_deprecated_uidplus_data, type: Enum[
        true, :up_to_max_size, false
      ]

      # The maximum +uid-set+ size that ResponseParser will parse into
      # deprecated UIDPlusData.  This limit only applies when
      # parser_use_deprecated_uidplus_data is not +false+.
      #
      # <em>(Parser support for +UIDPLUS+ added in +v0.3.2+.)</em>
      #
      # <em>Support for limiting UIDPlusData to a maximum size was added in
      # +v0.3.8+, +v0.4.19+, and +v0.5.6+.</em>
      #
      # <em>UIDPlusData will be removed in +v0.6+.</em>
      #
      # ==== Versioned Defaults
      #
      # Because this limit guards against a remote server causing catastrophic
      # memory exhaustion, the versioned default (used by #load_defaults) also
      # applies to versions without the feature.
      #
      # * +0.3+ and prior: <tt>10,000</tt>
      # * +0.4+: <tt>1,000</tt>
      # * +0.5+: <tt>100</tt>
      # * +0.6+: <tt>0</tt>
      #
      attr_accessor :parser_max_deprecated_uidplus_data_size, type: Integer

      # Creates a new config object and initialize its attribute with +attrs+.
      #
      # If +parent+ is not given, the global config is used by default.
      #
      # If a block is given, the new config object is yielded to it.
      def initialize(parent = Config.global, **attrs)
        super(parent)
        update(**attrs)
        yield self if block_given?
      end

      # :call-seq: update(**attrs) -> self
      #
      # Assigns all of the provided +attrs+ to this config, and returns +self+.
      #
      # An ArgumentError is raised unless every key in +attrs+ matches an
      # assignment method on Config.
      #
      # >>>
      #   *NOTE:*  #update is not atomic.  If an exception is raised due to an
      #   invalid attribute value, +attrs+ may be partially applied.
      def update(**attrs)
        unless (bad = attrs.keys.reject { respond_to?(:"#{_1}=") }).empty?
          raise ArgumentError, "invalid config options: #{bad.join(", ")}"
        end
        attrs.each do send(:"#{_1}=", _2) end
        self
      end

      # :call-seq:
      #   with(**attrs) -> config
      #   with(**attrs) {|config| } -> result
      #
      # Without a block, returns a new config which inherits from self.  With a
      # block, yields the new config and returns the block's result.
      #
      # If no keyword arguments are given, an ArgumentError will be raised.
      #
      # If +self+ is frozen, the copy will also be frozen.
      def with(**attrs)
        attrs.empty? and
          raise ArgumentError, "expected keyword arguments, none given"
        copy = new(**attrs)
        copy.freeze if frozen?
        block_given? ? yield(copy) : copy
      end

      # :call-seq: load_defaults(version) -> self
      #
      # Resets the current config to behave like the versioned default
      # configuration for +version+.  #parent will not be changed.
      #
      # Some config attributes default to inheriting from their #parent (which
      # is usually Config.global) and are left unchanged, for example: #debug.
      #
      # See Config@Versioned+defaults and Config@Named+defaults.
      def load_defaults(version)
        [Numeric, Symbol, String].any? { _1 === version } or
          raise ArgumentError, "expected number or symbol, got %p" % [version]
        update(**Config[version].defaults_hash)
      end

      # :call-seq: to_h -> hash
      #
      # Returns all config attributes in a hash.
      def to_h; data.members.to_h { [_1, send(_1)] } end

      protected

      def defaults_hash
        to_h.reject {|k,v| DEFAULT_TO_INHERIT.include?(k) }
      end

      @default = new(
        debug: false,
        open_timeout: 30,
        idle_response_timeout: 5,
        sasl_ir: true,
        max_response_size: nil,
        responses_without_block: :silence_deprecation_warning,
        parser_use_deprecated_uidplus_data: true,
        parser_max_deprecated_uidplus_data_size: 1000,
      ).freeze

      @global = default.new

      version_defaults[:default] = Config[default.send(:defaults_hash)]

      version_defaults[0r] = Config[:default].dup.update(
        sasl_ir: false,
        max_response_size: nil,
        parser_use_deprecated_uidplus_data: true,
        parser_max_deprecated_uidplus_data_size: 10_000,
      ).freeze
      version_defaults[0.0r] = Config[0r]
      version_defaults[0.1r] = Config[0r]
      version_defaults[0.2r] = Config[0r]
      version_defaults[0.3r] = Config[0r]

      version_defaults[0.4r] = Config[0.3r].dup.update(
        sasl_ir: true,
        parser_max_deprecated_uidplus_data_size: 1000,
      ).freeze

      version_defaults[0.5r] = Config[0.4r].dup.update(
        max_response_size: 512 << 20, # 512 MiB
        responses_without_block: :warn,
        parser_use_deprecated_uidplus_data: :up_to_max_size,
        parser_max_deprecated_uidplus_data_size: 100,
      ).freeze

      version_defaults[0.6r] = Config[0.5r].dup.update(
        responses_without_block: :frozen_dup,
        parser_use_deprecated_uidplus_data: false,
        parser_max_deprecated_uidplus_data_size: 0,
      ).freeze

      version_defaults[0.7r] = Config[0.6r].dup.update(
      ).freeze

      # Safe conversions one way only:
      #   0.6r.to_f == 0.6  # => true
      #   0.6 .to_r == 0.6r # => false
      version_defaults.to_a.each do |k, v|
        next unless k.is_a? Rational
        version_defaults[k.to_f] = v
      end

      current = VERSION.to_r
      version_defaults[:original] = Config[0]
      version_defaults[:current]  = Config[current]
      version_defaults[:next]     = Config[current + 0.1r]

      version_defaults[:future]   = Config[0.7r]

      version_defaults.freeze

      if ($VERBOSE || $DEBUG) && self[:current].to_h != self[:default].to_h
        warn "Misconfigured Net::IMAP::Config[:current] => %p,\n" \
             " not equal to Net::IMAP::Config[:default] => %p" % [
                self[:current].to_h, self[:default].to_h
              ]
      end
    end
  end
end
