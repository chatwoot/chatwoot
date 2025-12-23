# frozen_string_literal: true

# Net::IMAP authenticator for the "`DIGEST-MD5`" SASL mechanism type, specified
# in RFC-2831[https://tools.ietf.org/html/rfc2831].  See Net::IMAP#authenticate.
#
# == Deprecated
#
# "+DIGEST-MD5+" has been deprecated by
# RFC-6331[https://tools.ietf.org/html/rfc6331] and should not be relied on for
# security.  It is included for compatibility with existing servers.
class Net::IMAP::SASL::DigestMD5Authenticator
  STAGE_ONE = :stage_one
  STAGE_TWO = :stage_two
  STAGE_DONE = :stage_done
  private_constant :STAGE_ONE, :STAGE_TWO, :STAGE_DONE

  # Authentication identity: the identity that matches the #password.
  #
  # RFC-2831[https://tools.ietf.org/html/rfc2831] uses the term +username+.
  # "Authentication identity" is the generic term used by
  # RFC-4422[https://tools.ietf.org/html/rfc4422].
  # RFC-4616[https://tools.ietf.org/html/rfc4616] and many later RFCs abbreviate
  # this to +authcid+.
  attr_reader :username
  alias authcid username

  # A password or passphrase that matches the #username.
  #
  # The +password+ will be used to create the response digest.
  attr_reader :password

  # Authorization identity: an identity to act as or on behalf of.  The identity
  # form is application protocol specific.  If not provided or left blank, the
  # server derives an authorization identity from the authentication identity.
  # The server is responsible for verifying the client's credentials and
  # verifying that the identity it associates with the client's authentication
  # identity is allowed to act as (or on behalf of) the authorization identity.
  #
  # For example, an administrator or superuser might take on another role:
  #
  #     imap.authenticate "DIGEST-MD5", "root", ->{passwd}, authzid: "user"
  #
  attr_reader :authzid

  # :call-seq:
  #   new(username,  password,  authzid = nil, **options) -> authenticator
  #   new(username:, password:, authzid:  nil, **options) -> authenticator
  #   new(authcid:,  password:, authzid:  nil, **options) -> authenticator
  #
  # Creates an Authenticator for the "+DIGEST-MD5+" SASL mechanism.
  #
  # Called by Net::IMAP#authenticate and similar methods on other clients.
  #
  # ==== Parameters
  #
  # * #authcid  ― Authentication identity that is associated with #password.
  #
  #   #username ― An alias for +authcid+.
  #
  # * #password ― A password or passphrase associated with this #authcid.
  #
  # * _optional_ #authzid  ― Authorization identity to act as or on behalf of.
  #
  #   When +authzid+ is not set, the server should derive the authorization
  #   identity from the authentication identity.
  #
  # * _optional_ +warn_deprecation+ — Set to +false+ to silence the warning.
  #
  # Any other keyword arguments are silently ignored.
  def initialize(user = nil, pass = nil, authz = nil,
                 username: nil, password: nil, authzid: nil,
                 authcid: nil, secret: nil,
                 warn_deprecation: true, **)
    username = authcid || username || user or
      raise ArgumentError, "missing username (authcid)"
    password ||= secret || pass or raise ArgumentError, "missing password"
    authzid  ||= authz
    if warn_deprecation
      warn "WARNING: DIGEST-MD5 SASL mechanism was deprecated by RFC6331."
      # TODO: recommend SCRAM instead.
    end
    require "digest/md5"
    require "strscan"
    @username, @password, @authzid = username, password, authzid
    @nc, @stage = {}, STAGE_ONE
  end

  def initial_response?; false end

  # Responds to server challenge in two stages.
  def process(challenge)
    case @stage
    when STAGE_ONE
      @stage = STAGE_TWO
      sparams = {}
      c = StringScanner.new(challenge)
      while c.scan(/(?:\s*,)?\s*(\w+)=("(?:[^\\"]|\\.)*"|[^,]+)\s*/)
        k, v = c[1], c[2]
        if v =~ /^"(.*)"$/
          v = $1
          if v =~ /,/
            v = v.split(',')
          end
        end
        sparams[k] = v
      end

      raise Net::IMAP::DataFormatError, "Bad Challenge: '#{challenge}'" unless c.eos? and sparams['qop']
      raise Net::IMAP::Error, "Server does not support auth (qop = #{sparams['qop'].join(',')})" unless sparams['qop'].include?("auth")

      response = {
        :nonce => sparams['nonce'],
        :username => @username,
        :realm => sparams['realm'],
        :cnonce => Digest::MD5.hexdigest("%.15f:%.15f:%d" % [Time.now.to_f, rand, Process.pid.to_s]),
        :'digest-uri' => 'imap/' + sparams['realm'],
        :qop => 'auth',
        :maxbuf => 65535,
        :nc => "%08d" % nc(sparams['nonce']),
        :charset => sparams['charset'],
      }

      response[:authzid] = @authzid unless @authzid.nil?

      # now, the real thing
      a0 = Digest::MD5.digest( [ response.values_at(:username, :realm), @password ].join(':') )

      a1 = [ a0, response.values_at(:nonce,:cnonce) ].join(':')
      a1 << ':' + response[:authzid] unless response[:authzid].nil?

      a2 = "AUTHENTICATE:" + response[:'digest-uri']
      a2 << ":00000000000000000000000000000000" if response[:qop] and response[:qop] =~ /^auth-(?:conf|int)$/

      response[:response] = Digest::MD5.hexdigest(
        [
          Digest::MD5.hexdigest(a1),
          response.values_at(:nonce, :nc, :cnonce, :qop),
          Digest::MD5.hexdigest(a2)
        ].join(':')
      )

      return response.keys.map {|key| qdval(key.to_s, response[key]) }.join(',')
    when STAGE_TWO
      @stage = STAGE_DONE
      # if at the second stage, return an empty string
      if challenge =~ /rspauth=/
        return ''
      else
        raise ResponseParseError, challenge
      end
    else
      raise ResponseParseError, challenge
    end
  end

  def done?; @stage == STAGE_DONE end

  private

  def nc(nonce)
    if @nc.has_key? nonce
      @nc[nonce] = @nc[nonce] + 1
    else
      @nc[nonce] = 1
    end
    return @nc[nonce]
  end

  # some responses need quoting
  def qdval(k, v)
    return if k.nil? or v.nil?
    if %w"username authzid realm nonce cnonce digest-uri qop".include? k
      v = v.gsub(/([\\"])/, "\\\1")
      return '%s="%s"' % [k, v]
    else
      return '%s=%s' % [k, v]
    end
  end

end
