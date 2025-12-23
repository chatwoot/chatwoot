# frozen_string_literal: true

RFCS = {

  # Historic IMAP RFCs
  822  => "Internet Message Format (OBSOLETE)",
  1730 => "IMAP4 (OBSOLETE)",
  1731 => "IMAP4 Authentication Mechanisms (OBSOLETE)",
  2060 => "IMAP4rev1 (OBSOLETE)",
  2061 => "IMAP4 Compatibility with IMAP2bis",
  2062 => "Internet Message Access Protocol - Obsolete Syntax",
  2086 => "IMAP ACL (OBSOLETE)",
  2087 => "IMAP QUOTA (OBSOLETE)",
  2088 => "IMAP LITERAL+ (OBSOLETE)",
  2095 => "IMAP/POP AUTHorize Extension for CRAM-MD5 (OBSOLETE)",
  2192 => "IMAP URL Scheme (OBSOLETE)",
  2222 => "SASL (OBSOLETE)",
  2359 => "IMAP UIDPLUS (OBSOLETE)",
  2822 => "Internet Message Format (OBSOLETE)",
  3348 => "IMAP CHILDREN (OBSOLETED)",
  4551 => "IMAP CONDSTORE (OBSOLETE)",
  5162 => "IMAP QRESYNC (OBSOLETE)",
  6237 => "IMAP MULTISEARCH (OBSOLETE)",

  # Core IMAP RFCs
  3501 => "IMAP4rev1", # supported by nearly all email servers
  4466 => "Collected Extensions to IMAP4 ABNF",
  9051 => "IMAP4rev2", # not widely supported yet

  # RFC-9051 Normative References (not a complete list)
  2152 => "UTF-7",
  2180 => "IMAP4 Multi-Accessed Mailbox Practice",
  2683 => "IMAP4 Implementation Recommendations",
  3503 => "Message Disposition Notification (MDN) profile IMAP",
  5234 => "ABNF",
  5788 => "IMAP4 keyword registry",

  # Internet Message format and envelope and body structure
  5322 => "Internet Message Format (current)",

  1864 => "[MD5]: The Content-MD5 Header Field",
  2045 => "[MIME-IMB]:  MIME Part One: Format of Internet Message Bodies",
  2046 => "[MIME-IMT]:  MIME Part Two: Media Types",
  2047 => "[MIME-HDRS]: MIME Part Three: Header Extensions for Non-ASCII Text",
  2183 => "[DISPOSITION]: The Content-Disposition Header",
  2231 => "MIME Parameter Value and Encoded Word Extensions: " \
          "Character Sets, Languages, and Continuations",
  2557 => "[LOCATION]: MIME Encapsulation of Aggregate Documents",
  2978 => "[CHARSET]: IANA Charset Registration Procedures, BCP 19",
  3282 => "[LANGUAGE-TAGS]: Content Language Headers",
  6532 => "[I18N-HDRS]: Internationalized Email Headers",

  # SASL
  4422 => "SASL, EXTERNAL",

  # stringprep
  3454 => "stringprep",
  4013 => "SASLprep",
  8265 => "PRECIS", # obsoletes SASLprep?

  # SASL mechanisms (not a complete list)
  2195 => "SASL CRAM-MD5",
  4505 => "SASL ANONYMOUS",
  4616 => "SASL PLAIN",
  4752 => "SASL GSSAPI (Kerberos V5)",
  5801 => "SASL GS2-*, GS2-KRB5",
  5802 => "SASL SCRAM-*, SCRAM-SHA-1, SCRAM-SHA1-PLUS",
  5803 => "LDAP Schema for Storing SCRAM Secrets",
  6331 => "SASL DIGEST-MD5",
  6595 => "SASL SAML20",
  6616 => "SASL OPENID20",
  7628 => "SASL OAUTH10A, OAUTHBEARER",
  7677 => "SASL SCRAM-SHA-256, SCRAM-SHA256-PLUS",

  # "Informational" RFCs
  1733 => "Distributed E-Mail Models in IMAP4",
  4549 => "Synchronization Operations for Disconnected IMAP4 Clients",

  # TLS and other security concerns
  2595 => "Using TLS with IMAP, POP3 and ACAP",
  6151 => "Updated Security Considerations for MD5 Message-Digest and HMAC-MD5",
  7525 => "Recommendations for Secure Use of TLS and DTLS",
  7818 => "Updated TLS Server Identity Check Procedure for Email Protocols",
  8314 => "Cleartext Considered Obsolete: Use of TLS for Email",
  8996 => "Deprecating TLS 1.0 and TLS 1.1,",

  # related email specifications
  6376 => "DomainKeys Identified Mail (DKIM) Signatures",
  6409 => "Message Submission for Mail",

  # Other IMAP4 "Standards Track" RFCs
  5092 => "IMAP URL Scheme",
  5593 => "IMAP URL Access Identifier Extension",
  5530 => "IMAP Response Codes",
  6186 => "Use of SRV Records for Locating Email Submission/Access Services",
  8305 => "Happy Eyeballs Version 2: Better Connectivity Using Concurrency",

  # IMAP4 Extensions
  2177 => "IMAP IDLE",
  2193 => "IMAP MAILBOX-REFERRALS",
  2221 => "IMAP LOGIN-REFERRALS",
  2342 => "IMAP NAMESPACE",
  2971 => "IMAP ID",
  3502 => "IMAP MULTIAPPEND",
  3516 => "IMAP BINARY",
  3691 => "IMAP UNSELECT",
  4314 => "IMAP ACL, RIGHTS=",
  4315 => "IMAP UIDPLUS",
  4467 => "IMAP URLAUTH",
  4469 => "IMAP CATENATE",
  4731 => "IMAP ESEARCH",
  4959 => "IMAP SASL-IR",
  4978 => "IMAP COMPRESS=DEFLATE",
  5032 => "IMAP WITHIN",
  5161 => "IMAP ENABLE",
  5182 => "IMAP SEARCHRES",
  5255 => "IMAP I18NLEVEL=1, I18NLEVEL=2, LANGUAGE",
  5256 => "IMAP SORT, THREAD",
  5257 => "IMAP ANNOTATE-EXPERIMENT-1",
  5258 => "IMAP LIST-EXTENDED",
  5259 => "IMAP CONVERT",
  5267 => "IMAP CONTEXT=SEARCH, CONTEXT=SORT, ESORT",
  5464 => "IMAP METADATA, METADATA-SERVER",
  5465 => "IMAP NOTIFY",
  5466 => "IMAP FILTERS",
  5524 => "IMAP URLAUTH=BINARY", # see also: [RFC Errata 6214]
  5550 => "IMAP URL-PARTIAL",
  5738 => "IMAP UTF8=ALL, UTF8=APPEND, UTF8=USER", # OBSOLETED by RFC6855
  5819 => "IMAP LIST-STATUS",
  5957 => "IMAP SORT=DISPLAY",
  6154 => "IMAP SPECIAL-USE, CREATE-SPECIAL-USE",
  6203 => "IMAP SEARCH=FUZZY",
  6785 => "IMAP IMAPSIEVE=",
  6851 => "IMAP MOVE",
  6855 => "IMAP UTF8=ACCEPT, UTF8=ONLY",
  7162 => "IMAP CONDSTORE, QRESYNC",
  7377 => "IMAP MULTISEARCH",
  7888 => "IMAP LITERAL+, LITERAL-",
  7889 => "IMAP APPENDLIMIT",
  8437 => "IMAP UNAUTHENTICATE",
  8438 => "IMAP STATUS=SIZE",
  8440 => "IMAP LIST-MYRIGHTS",
  8474 => "IMAP OBJECTID",
  8508 => "IMAP REPLACE",
  8514 => "IMAP SAVEDATE",
  8970 => "IMAP PREVIEW",
  9208 => "IMAP QUOTA, QUOTA=, QUOTASET",

  # etc...
  3629 => "UTF8",
  6857 => "Post-Delivery Message Downgrading for I18n Email Messages",

}.freeze

task :rfcs => RFCS.keys.map {|n| "rfcs/rfc%04d.txt" % [n] }

RFC_RE = %r{rfcs/rfc(\d+).*\.txt}.freeze
rule RFC_RE do |t|
  require "fileutils"
  FileUtils.mkpath "rfcs"
  require "net/http"
  t.name =~ RFC_RE
  rfc_url = URI("https://www.rfc-editor.org/rfc/rfc#$1.txt")
  rfc_txt = Net::HTTP.get(rfc_url)
  File.write(t.name, rfc_txt)
end

CLEAN.include "rfcs/rfc*.txt"
