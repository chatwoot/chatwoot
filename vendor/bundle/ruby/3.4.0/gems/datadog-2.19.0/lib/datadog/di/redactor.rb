# frozen_string_literal: true

module Datadog
  module DI
    # Provides logic to identify sensitive information in snapshots captured
    # by dynamic instrumentation.
    #
    # Redaction can be performed based on identifier or attribute name,
    # or class name of said identifier or attribute. Redaction does not take
    # into account variable values.
    #
    # There is a built-in list of identifier names which will be subject to
    # redaction. Additional names can be provided by the user via the
    # settings.dynamic_instrumentation.redacted_identifiers setting or
    # the DD_DYNAMIC_INSTRUMENTATION_REDACTED_IDENTIFIERS environment
    # variable. Currently no class names are subject to redaction by default;
    # class names can be provided via the
    # settings.dynamic_instrumentation.redacted_type_names setting or
    # DD_DYNAMIC_INSTRUMENTATION_REDACTED_TYPES environment variable.
    #
    # Redacted identifiers must match exactly to an attribute name, a key
    # in a hash or a variable name. Redacted types can either be matched
    # exactly or, if the name is suffixed with an asterisk (*), any class
    # whose name contains the specified prefix will be subject to redaction.
    #
    # When specifying class (type) names to be redacted, user must specify
    # fully-qualified names. For example, if `Token` or `Token*` are
    # specified to be redacted, instances of ::Token will be redacted
    # but instances of ::Foo::Token will not be. To redact the latter,
    # specify `Foo::Token` or `::Foo::Token` as redacted types.
    #
    # This class does not perform redaction itself (i.e., value replacement
    # with a placeholder). This replacement is performed by Serializer.
    #
    # @api private
    class Redactor
      def initialize(settings)
        @settings = settings
      end

      attr_reader :settings

      def redact_identifier?(name)
        redacted_identifiers.include?(normalize(name))
      end

      def redact_type?(value)
        # Classses can be nameless, do not attempt to redact in that case.
        if (cls_name = value.class.name)
          redacted_type_names_regexp.match?(cls_name)
        else
          false
        end
      end

      private

      def redacted_identifiers
        @redacted_identifiers ||= begin
          names = DEFAULT_REDACTED_IDENTIFIERS + settings.dynamic_instrumentation.redacted_identifiers
          names.map! do |name|
            normalize(name)
          end
          Set.new(names)
        end
      end

      def redacted_type_names_regexp
        @redacted_type_names_regexp ||= begin
          names = settings.dynamic_instrumentation.redacted_type_names
          names = names.map do |name|
            if name.start_with?("::")
              # :: prefix is redundant, all names are expected to be
              # fully-qualified.
              #
              # Defaulting to empty string is for steep.
              name = name[2...name.length] || ""
            end
            if name.end_with?("*")
              # Defaulting to empty string is for steep.
              name = name[0..-2] || ""
              suffix = ".*"
            else
              suffix = ""
            end
            Regexp.escape(name) + suffix
          end.join("|")
          Regexp.new("\\A(?:#{names})\\z")
        end
      end

      # Copied from dd-trace-py
      DEFAULT_REDACTED_IDENTIFIERS = [
        "2fa",
        "accesstoken",
        "aiohttpsession",
        "apikey",
        "apisecret",
        "apisignature",
        "appkey",
        "applicationkey",
        "auth",
        "authorization",
        "authtoken",
        "ccnumber",
        "certificatepin",
        "cipher",
        "clientid",
        "clientsecret",
        "connectionstring",
        "connectsid",
        "cookie",
        "credentials",
        "creditcard",
        "csrf",
        "csrftoken",
        "cvv",
        "databaseurl",
        "dburl",
        "encryptionkey",
        "encryptionkeyid",
        "geolocation",
        "gpgkey",
        "ipaddress",
        "jti",
        "jwt",
        "licensekey",
        "masterkey",
        "mysqlpwd",
        "nonce",
        "oauth",
        "oauthtoken",
        "otp",
        "passhash",
        "passwd",
        "password",
        "passwordb",
        "pemfile",
        "pgpkey",
        "phpsessid",
        "pin",
        "pincode",
        "pkcs8",
        "privatekey",
        "publickey",
        "pwd",
        "recaptchakey",
        "refreshtoken",
        "routingnumber",
        "salt",
        "secret",
        "secretkey",
        "secrettoken",
        "securityanswer",
        "securitycode",
        "securityquestion",
        "serviceaccountcredentials",
        "session",
        "sessionid",
        "sessionkey",
        "setcookie",
        "signature",
        "signaturekey",
        "sshkey",
        "ssn",
        "symfony",
        "token",
        "transactionid",
        "twiliotoken",
        "usersession",
        "voterid",
        "xapikey",
        "xauthtoken",
        "xcsrftoken",
        "xforwardedfor",
        "xrealip",
        "xsrf",
        "xsrftoken",
      ]

      # Input can be a string or a symbol.
      def normalize(str)
        str.to_s.strip.downcase.gsub(/[-_$@]/, "")
      end
    end
  end
end
