Version 3.2.0
=============

Compatibility
-------------

* Ruby >= 2.7
  - Support for Ruby 2.6 has been removed. Note that Ruby 2.6 reached the
    end-of-life in 2022-04.
    [[GitHub #639]](https://github.com/ruby/openssl/pull/639)
* OpenSSL >= 1.0.2 or LibreSSL >= 3.1

Notable changes
---------------

* Add a stub gemspec for JRuby, which depends on the `jruby-openssl` gem.
  [[GitHub #598]](https://github.com/ruby/openssl/pull/598)
* Add support for the FIPS module in OpenSSL 3.0/3.1.
  [[GitHub #608]](https://github.com/ruby/openssl/pull/608)
* Rework `OpenSSL::PKey` routines for loading DER or PEM encoded keys for better
  compatibility with OpenSSL 3.0/3.1 with the FIPS module.
  [[GitHub #615]](https://github.com/ruby/openssl/pull/615)
  [[GitHub #669]](https://github.com/ruby/openssl/pull/669)
* Add `OpenSSL::Provider` module for loading and unloading OpenSSL 3 providers.
  [[GitHub #635]](https://github.com/ruby/openssl/pull/635)
* Add `OpenSSL::PKey.new_raw_private_key`, `.new_raw_public_key`,
  `OpenSSL::PKey::PKey#raw_private_key`, and `#raw_public_key` for public key
  algorithms that use "raw private/public key", such as X25519 and Ed25519.
  [[GitHub #646]](https://github.com/ruby/openssl/pull/646)
* Improve OpenSSL error messages to include additional information when
  it is available in OpenSSL's error queue.
  [[GitHub #648]](https://github.com/ruby/openssl/pull/648)
* Change `OpenSSL::SSL::SSLContext#ca_file=` and `#ca_path=` to raise
  `OpenSSL::SSL::SSLError` instead of printing a warning message.
  [[GitHub #659]](https://github.com/ruby/openssl/pull/659)
* Allow `OpenSSL::X509::ExtensionFactory#create_extension` to take OIDs in the
  dotted-decimal notation.
  [[GitHub #141]](https://github.com/ruby/openssl/pull/141)


Version 3.1.0
=============

Ruby/OpenSSL 3.1 will be maintained for the lifetime of Ruby 3.2.

Merged bug fixes in 2.2.3 and 3.0.2. Among the new features and changes are:

Notable changes
---------------

* Add `OpenSSL::SSL::SSLContext#ciphersuites=` to allow setting TLS 1.3 cipher
  suites.
  [[GitHub #493]](https://github.com/ruby/openssl/pull/493)
* Add `OpenSSL::SSL::SSLSocket#export_keying_material` for exporting keying
  material of the session, as defined in RFC 5705.
  [[GitHub #530]](https://github.com/ruby/openssl/pull/530)
* Add `OpenSSL::SSL::SSLContext#keylog_cb=` for setting the TLS key logging
  callback, which is useful for supporting NSS's SSLKEYLOGFILE debugging output.
  [[GitHub #536]](https://github.com/ruby/openssl/pull/536)
* Remove the default digest algorithm from `OpenSSL::OCSP::BasicResponse#sign`
  and `OpenSSL::OCSP::Request#sign`. Omitting the 5th parameter of these
  methods used to be equivalent of specifying SHA-1. This default value is now
  removed and we will let the underlying OpenSSL library decide instead.
  [[GitHub #507]](https://github.com/ruby/openssl/pull/507)
* Add `OpenSSL::BN#mod_sqrt`.
  [[GitHub #553]](https://github.com/ruby/openssl/pull/553)
* Allow calling `OpenSSL::Cipher#update` with an empty string. This was
  prohibited to workaround an ancient bug in OpenSSL.
  [[GitHub #568]](https://github.com/ruby/openssl/pull/568)
* Fix build on platforms without socket support, such as WASI. `OpenSSL::SSL`
  will not be defined if OpenSSL is compiled with `OPENSSL_NO_SOCK`.
  [[GitHub #558]](https://github.com/ruby/openssl/pull/558)
* Improve support for recent LibreSSL versions. This includes HKDF support in
  LibreSSL 3.6 and Ed25519 support in LibreSSL 3.7.


Version 3.0.2
=============

Merged changes in 2.2.3. Additionally, the following issues are fixed by this
release.

Bug fixes
---------

* Fix OpenSSL::PKey::EC#check_key not working correctly on OpenSSL 3.0.
  [[GitHub #563]](https://github.com/ruby/openssl/issues/563)
  [[GitHub #580]](https://github.com/ruby/openssl/pull/580)


Version 3.0.1
=============

Merged changes in 2.1.4 and 2.2.2. Additionally, the following issues are fixed
by this release.

Bug fixes
---------

* Add missing type check in OpenSSL::PKey::PKey#sign's optional parameters.
  [[GitHub #531]](https://github.com/ruby/openssl/pull/531)
* Work around OpenSSL 3.0's HMAC issues with a zero-length key.
  [[GitHub #538]](https://github.com/ruby/openssl/pull/538)
* Fix a regression in OpenSSL::PKey::DSA.generate's default of 'q' size.
  [[GitHub #483]](https://github.com/ruby/openssl/issues/483)
  [[GitHub #539]](https://github.com/ruby/openssl/pull/539)
* Restore OpenSSL::PKey.read's ability to decode "openssl ecparam -genkey"
  output when linked against OpenSSL 3.0.
  [[GitHub #535]](https://github.com/ruby/openssl/pull/535)
  [[GitHub #540]](https://github.com/ruby/openssl/pull/540)
* Restore error checks in OpenSSL::PKey::EC#{to_der,to_pem}.
  [[GitHub #541]](https://github.com/ruby/openssl/pull/541)


Version 3.0.0
=============

Compatibility notes
-------------------

* OpenSSL 1.0.1 and Ruby 2.3-2.5 are no longer supported.
  [[GitHub #396]](https://github.com/ruby/openssl/pull/396)
  [[GitHub #466]](https://github.com/ruby/openssl/pull/466)

* OpenSSL 3.0 support is added. It is the first major version bump from OpenSSL
  1.1 and contains incompatible changes that affect Ruby/OpenSSL.
  Note that OpenSSL 3.0 support is preliminary and not all features are
  currently available:
  [[GitHub #369]](https://github.com/ruby/openssl/issues/369)

  - Deprecate the ability to modify `OpenSSL::PKey::PKey` instances. OpenSSL 3.0
    made EVP_PKEY structure immutable, and hence the following methods are not
    available when Ruby/OpenSSL is linked against OpenSSL 3.0.
    [[GitHub #480]](https://github.com/ruby/openssl/pull/480)

    - `OpenSSL::PKey::RSA#set_key`, `#set_factors`, `#set_crt_params`
    - `OpenSSL::PKey::DSA#set_pqg`, `#set_key`
    - `OpenSSL::PKey::DH#set_pqg`, `#set_key`, `#generate_key!`
    - `OpenSSL::PKey::EC#private_key=`, `#public_key=`, `#group=`, `#generate_key!`

  - Deprecate `OpenSSL::Engine`. The ENGINE API has been deprecated in OpenSSL 3.0
    in favor of the new "provider" concept and will be removed in a future
    version.
    [[GitHub #481]](https://github.com/ruby/openssl/pull/481)

* `OpenSSL::SSL::SSLContext#tmp_ecdh_callback` has been removed. It has been
  deprecated since v2.0.0 because it is incompatible with modern OpenSSL
  versions.
  [[GitHub #394]](https://github.com/ruby/openssl/pull/394)

* `OpenSSL::SSL::SSLSocket#read` and `#write` now raise `OpenSSL::SSL::SSLError`
  if called before a TLS connection is established. Historically, they
  read/wrote unencrypted data to the underlying socket directly in that case.
  [[GitHub #9]](https://github.com/ruby/openssl/issues/9)
  [[GitHub #469]](https://github.com/ruby/openssl/pull/469)


Notable changes
---------------

* Enhance OpenSSL::PKey's common interface.
  [[GitHub #370]](https://github.com/ruby/openssl/issues/370)

  - Key deserialization: Enhance `OpenSSL::PKey.read` to handle PEM encoding of
    DH parameters, which used to be only deserialized by `OpenSSL::PKey::DH.new`.
    [[GitHub #328]](https://github.com/ruby/openssl/issues/328)
  - Key generation: Add `OpenSSL::PKey.generate_parameters` and
    `OpenSSL::PKey.generate_key`.
    [[GitHub #329]](https://github.com/ruby/openssl/issues/329)
  - Public key signing: Enhance `OpenSSL::PKey::PKey#sign` and `#verify` to use
    the new EVP_DigestSign() family to enable PureEdDSA support on OpenSSL 1.1.1
    or later. They also now take optional algorithm-specific parameters for more
    control.
    [[GitHub #329]](https://github.com/ruby/openssl/issues/329)
  - Low-level public key signing and verification: Add
    `OpenSSL::PKey::PKey#sign_raw`, `#verify_raw`, and `#verify_recover`.
    [[GitHub #382]](https://github.com/ruby/openssl/issues/382)
  - Public key encryption: Add `OpenSSL::PKey::PKey#encrypt` and `#decrypt`.
    [[GitHub #382]](https://github.com/ruby/openssl/issues/382)
  - Key agreement: Add `OpenSSL::PKey::PKey#derive`.
    [[GitHub #329]](https://github.com/ruby/openssl/issues/329)
  - Key comparison: Add `OpenSSL::PKey::PKey#compare?` to conveniently check
    that two keys have common parameters and a public key.
    [[GitHub #383]](https://github.com/ruby/openssl/issues/383)

* Add `OpenSSL::BN#set_flags` and `#get_flags`. This can be used in combination
  with `OpenSSL::BN::CONSTTIME` to force constant-time computation.
  [[GitHub #417]](https://github.com/ruby/openssl/issues/417)

* Add `OpenSSL::BN#abs` to get the absolute value of the BIGNUM.
  [[GitHub #430]](https://github.com/ruby/openssl/issues/430)

* Add `OpenSSL::SSL::SSLSocket#getbyte`.
  [[GitHub #438]](https://github.com/ruby/openssl/issues/438)

* Add `OpenSSL::SSL::SSLContext#tmp_dh=`.
  [[GitHub #459]](https://github.com/ruby/openssl/pull/459)

* Add `OpenSSL::X509::Certificate.load` to load a PEM-encoded and concatenated
  list of X.509 certificates at once.
  [[GitHub #441]](https://github.com/ruby/openssl/pull/441)

* Change `OpenSSL::X509::Certificate.new` to attempt to deserialize the given
  string first as DER encoding first and then as PEM encoding to ensure the
  round-trip consistency.
  [[GitHub #442]](https://github.com/ruby/openssl/pull/442)

* Update various part of the code base to use the modern API. No breaking
  changes are intended with this. This includes:

  - `OpenSSL::HMAC` uses the EVP API.
    [[GitHub #371]](https://github.com/ruby/openssl/issues/371)
  - `OpenSSL::Config` uses native OpenSSL API to parse config files.
    [[GitHub #342]](https://github.com/ruby/openssl/issues/342)


Version 2.2.3
=============

Bug fixes
---------

* Fix serveral methods in OpenSSL::PKey::EC::Point attempting to raise an error
  with an incorrect class, which would end up with a TypeError.
  [[GitHub #570]](https://github.com/ruby/openssl/pull/570)
* Fix OpenSSL::PKey::EC::Point#eql? and OpenSSL::PKey::EC::Group#eql?
  incorrectly treated OpenSSL's internal errors as "not equal".
  [[GitHub #564]](https://github.com/ruby/openssl/pull/564)
* Fix build with LibreSSL 3.5 or later.


Version 2.2.2
=============

Merged changes in 2.1.4.


Version 2.2.1
=============

Merged changes in 2.1.3. Additionally, the following issues are fixed by this
release.

Bug fixes
---------

* Fix crash in `OpenSSL::Timestamp::{Request,Response,TokenInfo}.new` when
  invalid arguments are given.
  [[GitHub #407]](https://github.com/ruby/openssl/pull/407)
* Fix `OpenSSL::Timestamp::Factory#create_timestamp` with LibreSSL on platforms
  where `time_t` has a different size from `long`.
  [[GitHub #454]](https://github.com/ruby/openssl/pull/454)


Version 2.2.0
=============

Compatibility notes
-------------------

* Remove unsupported MDC2, DSS, DSS1, and SHA algorithms.
* Remove `OpenSSL::PKCS7::SignerInfo#name` alias for `#issuer`.
  [[GitHub #266]](https://github.com/ruby/openssl/pull/266)
* Deprecate `OpenSSL::Config#add_value` and `#[]=` for future removal.
  [[GitHub #322]](https://github.com/ruby/openssl/pull/322)


Notable changes
---------------

* Change default `OpenSSL::SSL::SSLServer#listen` backlog argument from
  5 to `Socket::SOMAXCONN`.
  [[GitHub #286]](https://github.com/ruby/openssl/issues/286)
* Make `OpenSSL::HMAC#==` use a timing safe string comparison.
  [[GitHub #284]](https://github.com/ruby/openssl/pull/284)
* Add support for SHA3 and BLAKE digests.
  [[GitHub #282]](https://github.com/ruby/openssl/pull/282)
* Add `OpenSSL::SSL::SSLSocket.open` for opening a `TCPSocket` and
  returning an `OpenSSL::SSL::SSLSocket` for it.
  [[GitHub #225]](https://github.com/ruby/openssl/issues/225)
* Support marshalling of `OpenSSL::X509` and `OpenSSL::PKey` objects.
  [[GitHub #281]](https://github.com/ruby/openssl/pull/281)
  [[GitHub #363]](https://github.com/ruby/openssl/pull/363)
* Add `OpenSSL.secure_compare` for timing safe string comparison for
  strings of possibly unequal length.
  [[GitHub #280]](https://github.com/ruby/openssl/pull/280)
* Add `OpenSSL.fixed_length_secure_compare` for timing safe string
  comparison for strings of equal length.
  [[GitHub #269]](https://github.com/ruby/openssl/pull/269)
* Add `OpenSSL::SSL::SSLSocket#{finished_message,peer_finished_message}`
  for last finished message sent and received.
  [[GitHub #250]](https://github.com/ruby/openssl/pull/250)
* Add `OpenSSL::Timestamp` module for handing timestamp requests and
  responses.
  [[GitHub #204]](https://github.com/ruby/openssl/pull/204)
* Add helper methods for `OpenSSL::X509::Certificate`:
  `find_extension`, `subject_key_identifier`,
  `authority_key_identifier`, `crl_uris`, `ca_issuer_uris` and
  `ocsp_uris`, and for `OpenSSL::X509::CRL`:
  `find_extension` and `subject_key_identifier`.
  [[GitHub #260]](https://github.com/ruby/openssl/pull/260)
  [[GitHub #275]](https://github.com/ruby/openssl/pull/275)
  [[GitHub #293]](https://github.com/ruby/openssl/pull/293)
* Add `OpenSSL::ECPoint#add` for performing elliptic curve point addition.
  [[GitHub #261]](https://github.com/ruby/openssl/pull/261)
* Make `OpenSSL::PKey::RSA#{export,to_der}` check `key`, `factors`, and
  `crt_params` to do proper private key serialization.
  [[GitHub #258]](https://github.com/ruby/openssl/pull/258)
* Add `OpenSSL::SSL::{SSLSocket,SSLServer}#fileno`, returning the
  underlying socket file descriptor number.
  [[GitHub #247]](https://github.com/ruby/openssl/pull/247)
* Support client certificates with TLS 1.3, and support post-handshake
  authentication with OpenSSL 1.1.1+.
  [[GitHub #239]](https://github.com/ruby/openssl/pull/239)
* Add `OpenSSL::ASN1::ObjectId#==` for equality testing.
* Add `OpenSSL::X509::Extension#value_der` for the raw value of
  the extension.
  [[GitHub #234]](https://github.com/ruby/openssl/pull/234)
* Significantly reduce allocated memory in `OpenSSL::Buffering#do_write`.
  [[GitHub #212]](https://github.com/ruby/openssl/pull/212)
* Ensure all valid IPv6 addresses are considered valid as elements
  of subjectAlternativeName in certificates.
  [[GitHub #185]](https://github.com/ruby/openssl/pull/185)
* Allow recipient's certificate to be omitted in PCKS7#decrypt.
  [[GitHub #183]](https://github.com/ruby/openssl/pull/183)
* Add support for reading keys in PKCS #8 format and export via instance methods
  added to `OpenSSL::PKey` classes: `private_to_der`, `private_to_pem`,
  `public_to_der` and `public_to_pem`.
  [[GitHub #297]](https://github.com/ruby/openssl/pull/297)


Version 2.1.4
=============

Bug fixes
---------

* Do not use pkg-config if --with-openssl-dir option is specified.
 [[GitHub #486]](https://github.com/ruby/openssl/pull/486)


Version 2.1.3
=============

Bug fixes
---------

* Fix deprecation warnings on Ruby 3.0.
* Add ".include" directive support in `OpenSSL::Config`.
  [[GitHub #216]](https://github.com/ruby/openssl/pull/216)
* Fix handling of IPv6 address SANs.
  [[GitHub #185]](https://github.com/ruby/openssl/pull/185)
* Hostname verification failure with `OpenSSL::SSL::SSLContext#verify_hostname=`
  sets a proper error code.
  [[GitHub #350]](https://github.com/ruby/openssl/pull/350)
* Fix crash with `OpenSSL::BN.new(nil, 2)`.
  [[Bug #15760]](https://bugs.ruby-lang.org/issues/15760)
* `OpenSSL::SSL::SSLSocket#sys{read,write}` prevent internal string buffers from
  being modified by another thread.
  [[GitHub #453]](https://github.com/ruby/openssl/pull/453)
* Fix misuse of input record separator in `OpenSSL::Buffering` where it was
  for output.
* Fix wrong integer casting in `OpenSSL::PKey::EC#dsa_verify_asn1`.
  [[GitHub #460]](https://github.com/ruby/openssl/pull/460)
* `extconf.rb` explicitly checks that OpenSSL's version number is 1.0.1 or
  newer but also less than 3.0. Ruby/OpenSSL v2.1.x and v2.2.x will not support
  OpenSSL 3.0 API.
  [[GitHub #458]](https://github.com/ruby/openssl/pull/458)
* Activate `digest` gem correctly. `digest` library could go into an
  inconsistent state if there are multiple versions of `digest` is installed
  and `openssl` is `require`d before `digest`.
  [[GitHub #463]](https://github.com/ruby/openssl/pull/463)
* Fix GC.compact compatibility.
  [[GitHub #464]](https://github.com/ruby/openssl/issues/464)
  [[GitHub #465]](https://github.com/ruby/openssl/pull/465)


Version 2.1.2
=============

Merged changes in 2.0.9.


Version 2.1.1
=============

Merged changes in 2.0.8.


Version 2.1.0
=============

Notable changes
---------------

* Support for OpenSSL versions before 1.0.1 and LibreSSL versions before 2.5
  is removed.
  [[GitHub #86]](https://github.com/ruby/openssl/pull/86)
* OpenSSL::BN#negative?, #+@, and #-@ are added.
* OpenSSL::SSL::SSLSocket#connect raises a more informative exception when
  certificate verification fails.
  [[GitHub #99]](https://github.com/ruby/openssl/pull/99)
* OpenSSL::KDF module is newly added. In addition to PBKDF2-HMAC that has moved
  from OpenSSL::PKCS5, scrypt and HKDF are supported.
  [[GitHub #109]](https://github.com/ruby/openssl/pull/109)
  [[GitHub #173]](https://github.com/ruby/openssl/pull/173)
* OpenSSL.fips_mode is added. We had the setter, but not the getter.
  [[GitHub #125]](https://github.com/ruby/openssl/pull/125)
* OpenSSL::OCSP::Request#signed? is added.
* OpenSSL::ASN1 handles the indefinite length form better. OpenSSL::ASN1.decode
  no longer wrongly treats the end-of-contents octets as part of the content.
  OpenSSL::ASN1::ASN1Data#infinite_length is renamed to #indefinite_length.
  [[GitHub #98]](https://github.com/ruby/openssl/pull/98)
* OpenSSL::X509::Name#add_entry now accepts two additional keyword arguments
  'loc' and 'set'.
  [[GitHub #94]](https://github.com/ruby/openssl/issues/94)
* OpenSSL::SSL::SSLContext#min_version= and #max_version= are added to replace
  #ssl_version= that was built on top of the deprecated OpenSSL C API. Use of
  that method and the constant OpenSSL::SSL::SSLContext::METHODS is now
  deprecated.
  [[GitHub #142]](https://github.com/ruby/openssl/pull/142)
* OpenSSL::X509::Name#to_utf8 is added.
  [[GitHub #26]](https://github.com/ruby/openssl/issues/26)
  [[GitHub #143]](https://github.com/ruby/openssl/pull/143)
* OpenSSL::X509::{Extension,Attribute,Certificate,CRL,Revoked,Request} can be
  compared with == operator.
  [[GitHub #161]](https://github.com/ruby/openssl/pull/161)
* TLS Fallback Signaling Cipher Suite Value (SCSV) support is added.
  [[GitHub #165]](https://github.com/ruby/openssl/pull/165)
* Build failure with OpenSSL 1.1 built with no-deprecated is fixed.
  [[GitHub #160]](https://github.com/ruby/openssl/pull/160)
* OpenSSL::Buffering#write accepts an arbitrary number of arguments.
  [[Feature #9323]](https://bugs.ruby-lang.org/issues/9323)
  [[GitHub #162]](https://github.com/ruby/openssl/pull/162)
* OpenSSL::PKey::RSA#sign_pss and #verify_pss are added. They perform RSA-PSS
  signature and verification.
  [[GitHub #75]](https://github.com/ruby/openssl/issues/75)
  [[GitHub #76]](https://github.com/ruby/openssl/pull/76)
  [[GitHub #169]](https://github.com/ruby/openssl/pull/169)
* OpenSSL::SSL::SSLContext#add_certificate is added.
  [[GitHub #167]](https://github.com/ruby/openssl/pull/167)
* OpenSSL::PKey::EC::Point#to_octet_string is added.
  OpenSSL::PKey::EC::Point.new can now take String as the second argument.
  [[GitHub #177]](https://github.com/ruby/openssl/pull/177)


Version 2.0.9
=============

Security fixes
--------------

* OpenSSL::X509::Name#<=> could incorrectly return 0 (= equal) for non-equal
  objects. CVE-2018-16395 is assigned for this issue.
  https://hackerone.com/reports/387250

Bug fixes
---------

* Fixed OpenSSL::PKey::*.{new,generate} immediately aborting if the thread is
  interrupted.
  [[Bug #14882]](https://bugs.ruby-lang.org/issues/14882)
  [[GitHub #205]](https://github.com/ruby/openssl/pull/205)
* Fixed OpenSSL::X509::Name#to_s failing with OpenSSL::X509::NameError if
  called against an empty instance.
  [[GitHub #200]](https://github.com/ruby/openssl/issues/200)
  [[GitHub #211]](https://github.com/ruby/openssl/pull/211)


Version 2.0.8
=============

Bug fixes
---------

* OpenSSL::Cipher#pkcs5_keyivgen raises an error when a negative iteration
  count is given.
  [[GitHub #184]](https://github.com/ruby/openssl/pull/184)
* Fixed build with LibreSSL 2.7.
  [[GitHub #192]](https://github.com/ruby/openssl/issues/192)
  [[GitHub #193]](https://github.com/ruby/openssl/pull/193)


Version 2.0.7
=============

Bug fixes
---------

* OpenSSL::Cipher#auth_data= could segfault if called against a non-AEAD cipher.
  [[Bug #14024]](https://bugs.ruby-lang.org/issues/14024)
* OpenSSL::X509::Certificate#public_key= (and similar methods) could segfault
  when an instance of OpenSSL::PKey::PKey with no public key components is
  passed.
  [[Bug #14087]](https://bugs.ruby-lang.org/issues/14087)
  [[GitHub #168]](https://github.com/ruby/openssl/pull/168)


Version 2.0.6
=============

Bug fixes
---------

* The session_remove_cb set to an OpenSSL::SSL::SSLContext is no longer called
  during GC.
* A possible deadlock in OpenSSL::SSL::SSLSocket#sysread is fixed.
  [[GitHub #139]](https://github.com/ruby/openssl/pull/139)
* OpenSSL::BN#hash could return an unnormalized fixnum value on Windows.
  [[Bug #13877]](https://bugs.ruby-lang.org/issues/13877)
* OpenSSL::SSL::SSLSocket#sysread and #sysread_nonblock set the length of the
  destination buffer String to 0 on error.
  [[GitHub #153]](https://github.com/ruby/openssl/pull/153)
* Possible deadlock is fixed. This happened only when built with older versions
  of OpenSSL (before 1.1.0) or LibreSSL.
  [[GitHub #155]](https://github.com/ruby/openssl/pull/155)


Version 2.0.5
=============

Bug fixes
---------

* Reading a PEM/DER-encoded private key or certificate from an IO object did
  not work properly on mswin platforms.
  [[ruby/openssl#128]](https://github.com/ruby/openssl/issues/128)
* Broken length check in the PEM passphrase callback is fixed.
* It failed to compile when OpenSSL is configured without TLS 1.0 support.


Version 2.0.4
=============

Bug fixes
---------

* It now compiles with LibreSSL without renaming on Windows (mswin).
* A workaround for the error queue leak of X509_load_cert_crl_file() that
  causes random errors is added.
  [[Bug #11033]](https://bugs.ruby-lang.org/issues/11033)


Version 2.0.3
=============

Bug fixes
---------

* OpenSSL::ASN1::Constructive#each which was broken by 2.0.0 is fixed.
  [[ruby/openssl#96]](https://github.com/ruby/openssl/pull/96)
* Fixed build with static OpenSSL libraries on Windows.
  [[Bug #13080]](https://bugs.ruby-lang.org/issues/13080)
* OpenSSL::X509::Name#eql? which was broken by 2.0.0 is fixed.


Version 2.0.2
=============

Bug fixes
---------

* Fix build with early 0.9.8 series which did not have SSL_CTX_clear_options().
  [ruby-core:78693]


Version 2.0.1
=============

Bug fixes
---------

* A GC issue around OpenSSL::BN is fixed.
  [[ruby/openssl#87]](https://github.com/ruby/openssl/issues/87)
* OpenSSL::ASN1 now parses BER encoding of GeneralizedTime without seconds.
  [[ruby/openssl#88]](https://github.com/ruby/openssl/pull/88)


Version 2.0.0
=============

This is the first release of openssl gem, formerly a standard library of Ruby,
ext/openssl. This is the successor of the version included in Ruby 2.3.

Compatibility notes
-------------------

* Support for OpenSSL version 0.9.6 and 0.9.7 is completely removed. openssl gem
  still works with OpenSSL 0.9.8, but users are strongly encouraged to upgrade
  to at least 1.0.1, as OpenSSL < 1.0.1 will not receive any security fixes from
  the OpenSSL development team.

Supported platforms
-------------------

* OpenSSL 1.0.0, 1.0.1, 1.0.2, 1.1.0
* OpenSSL < 0.9.8 is no longer supported.
* LibreSSL 2.3, 2.4, 2.5
* Ruby 2.3, 2.4

Notable changes
---------------

* Add support for OpenSSL 1.1.0.
  [[Feature #12324]](https://bugs.ruby-lang.org/issues/12324)
* Add support for LibreSSL

* OpenSSL::Cipher

  - OpenSSL::Cipher#key= and #iv= reject too long inputs. They used to truncate
    silently. [[Bug #12561]](https://bugs.ruby-lang.org/issues/12561)

  - OpenSSL::Cipher#iv_len= is added. It allows changing IV (nonce) length if
    using AEAD ciphers.
    [[Bug #8667]](https://bugs.ruby-lang.org/issues/8667),
    [[Bug #10420]](https://bugs.ruby-lang.org/issues/10420),
    [[GH ruby/ruby#569]](https://github.com/ruby/ruby/pull/569),
    [[GH ruby/openssl#58]](https://github.com/ruby/openssl/pull/58)

  - OpenSSL::Cipher#auth_tag_len= is added. This sets the authentication tag
    length to be generated by an AEAD cipher.

* OpenSSL::OCSP

  - Accessor methods are added to OpenSSL::OCSP::CertificateId.
    [[Feature #7181]](https://bugs.ruby-lang.org/issues/7181)

  - OpenSSL::OCSP::Request and BasicResponse can be signed with non-SHA-1 hash
    algorithm. [[Feature #11552]](https://bugs.ruby-lang.org/issues/11552)

  - OpenSSL::OCSP::CertificateId and BasicResponse can be encoded into DER.

  - A new class OpenSSL::OCSP::SingleResponse is added for convenience.

  - OpenSSL::OCSP::BasicResponse#add_status accepts absolute times. They used to
    accept only relative seconds from the current time.

* OpenSSL::PKey

  - OpenSSL::PKey::EC follows the general PKey interface.
    [[Bug #6567]](https://bugs.ruby-lang.org/issues/6567)

  - OpenSSL::PKey.read raises OpenSSL::PKey::PKeyError instead of ArgumentError
    for consistency with OpenSSL::PKey::{DH,DSA,RSA,EC}#new.
    [[Bug #11774]](https://bugs.ruby-lang.org/issues/11774),
    [[GH ruby/openssl#55]](https://github.com/ruby/openssl/pull/55)

  - OpenSSL::PKey::EC::Group retrieved by OpenSSL::PKey::EC#group is no longer
    linked with the EC key. Modifications to the EC::Group have no effect on the
    key. [[GH ruby/openssl#71]](https://github.com/ruby/openssl/pull/71)

  - OpenSSL::PKey::EC::Point#to_bn allows specifying the point conversion form
    by the optional argument.

* OpenSSL::SSL

  - OpenSSL::SSL::SSLSocket#tmp_key is added. A client can call it after the
    connection is established to retrieve the ephemeral key.
    [[GH ruby/ruby#1318]](https://github.com/ruby/ruby/pull/1318)

  - The automatic ephemeral ECDH curve selection is enabled by default when
    built with OpenSSL >= 1.0.2 or LibreSSL.

  - OpenSSL::SSL::SSLContext#security_level= is added. You can set the "security
    level" of the SSL context. This is effective only when built with OpenSSL
    1.1.0.

  - A new option 'verify_hostname' is added to OpenSSL::SSL::SSLContext. When it
    is enabled, and the SNI hostname is also set, the hostname verification on
    the server certificate is automatically performed. It is now enabled by
    OpenSSL::SSL::SSLContext#set_params.
    [[GH ruby/openssl#60]](https://github.com/ruby/openssl/pull/60)

Removals
--------

* OpenSSL::Engine

  - OpenSSL::Engine.cleanup does nothing when built with OpenSSL 1.1.0.

* OpenSSL::SSL

  - OpenSSL::PKey::DH::DEFAULT_512 is removed. Hence servers no longer use
    512-bit DH group by default. It is considered too weak nowadays.
    [[Bug #11968]](https://bugs.ruby-lang.org/issues/11968),
    [[GH ruby/ruby#1196]](https://github.com/ruby/ruby/pull/1196)

  - RC4 cipher suites are removed from OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.
    RC4 is now considered to be weak.
    [[GH ruby/openssl#50]](https://github.com/ruby/openssl/pull/50)

Deprecations
------------

* OpenSSL::PKey

  - OpenSSL::PKey::RSA#n=, #e=, #d=, #p=, #q=, #dmp1=, #dmq1=, #iqmp=,
    OpenSSL::PKey::DSA#p=, #q=, #g=, #priv_key=, #pub_key=,
    OpenSSL::PKey::DH#p=, #g=, #priv_key= and #pub_key= are deprecated. They are
    disabled when built with OpenSSL 1.1.0, due to its API change. Instead,
    OpenSSL::PKey::RSA#set_key, #set_factors, #set_crt_params,
    OpenSSL::PKey::DSA#set_pqg, #set_key, OpenSSL::PKey::DH#set_pqg and #set_key
    are added.

* OpenSSL::Random

  - OpenSSL::Random.pseudo_bytes is deprecated, and not defined when built with
    OpenSSL 1.1.0. Use OpenSSL::Random.random_bytes instead.

* OpenSSL::SSL

  - OpenSSL::SSL::SSLContext#tmp_ecdh_callback is deprecated, as the underlying
    API SSL_CTX_set_tmp_ecdh_callback() is removed in OpenSSL 1.1.0. It was
    first added in Ruby 2.3.0. To specify the curve to be used in ephemeral
    ECDH, use OpenSSL::SSL::SSLContext#ecdh_curves=. The automatic curve
    selection is also now enabled by default when built with a capable OpenSSL.
