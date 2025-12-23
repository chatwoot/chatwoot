# encoding: us-ascii
# frozen_string_literal: true
module Mail
  module Constants
    white_space = %Q|\x9\x20|
    text        = %Q|\x1-\x8\xB\xC\xE-\x7f|
    field_name  = %Q|\x21-\x39\x3b-\x7e|
    qp_safe     = %Q|\x20-\x3c\x3e-\x7e|

    aspecial     = %Q|()<>[]:;@\\,."| # RFC5322
    tspecial     = %Q|()<>@,;:\\"/[]?=| # RFC2045
    sp           = %Q| |
    control      = %Q|\x00-\x1f\x7f-\xff|

    if control.respond_to?(:force_encoding)
      control = control.dup.force_encoding(Encoding::BINARY)
    end

    LAX_CRLF      = /\r?\n/
    WSP           = /[#{white_space}]/
    FWS           = /#{LAX_CRLF}#{WSP}*/
    UNFOLD_WS     = /#{LAX_CRLF}(#{WSP})/m
    TEXT          = /[#{text}]/ # + obs-text
    FIELD_NAME    = /[#{field_name}]+/
    FIELD_PREFIX  = /\A(#{FIELD_NAME})/
    FIELD_BODY    = /.+/m
    FIELD_LINE    = /^[#{field_name}]+:\s*.+$/
    FIELD_SPLIT   = /^(#{FIELD_NAME})\s*:\s*(#{FIELD_BODY})?$/
    HEADER_LINE   = /^([#{field_name}]+:\s*.+)$/
    HEADER_SPLIT  = /#{LAX_CRLF}(?!#{WSP})/

    QP_UNSAFE     = /[^#{qp_safe}]/
    QP_SAFE       = /[#{qp_safe}]/
    CONTROL_CHAR  = /[#{control}]/n
    ATOM_UNSAFE   = /[#{Regexp.quote aspecial}#{control}#{sp}]/n
    PHRASE_UNSAFE = /[#{Regexp.quote aspecial}#{control}]/n
    TOKEN_UNSAFE  = /[#{Regexp.quote tspecial}#{control}#{sp}]/n

    ENCODED_VALUE = %r{
      \=\?     # literal =?
      ([^?]+)  #
      \?       # literal ?
      ([QB])   # either a "Q" or a "B"
      \?       # literal ?
      .*?      # lazily match all characters
      \?\=     # literal ?=
    }mix # m is multi-line, i is case-insensitive, x is free-spacing

    FULL_ENCODED_VALUE = %r{ # Identical to ENCODED_VALUE but captures the whole rather than components of
      (
        \=\?    # literal =?
        [^?]+   #
        \?      # literal ?
        [QB]    # either a "Q" or a "B"
        \?      # literal ?
        .*?     # lazily match all characters
        \?\=    # literal ?=
      )
    }mix # m is multi-line, i is case-insensitive, x is free-spacing

    EMPTY          = ''
    SPACE          = ' '
    UNDERSCORE     = '_'
    HYPHEN         = '-'
    COLON          = ':'
    ASTERISK       = '*'
    CRLF           = "\r\n"
    CR             = "\r"
    LF             = "\n"
    CR_ENCODED     = "=0D"
    LF_ENCODED     = "=0A"
    CAPITAL_M      = 'M'
    EQUAL_LF       = "=\n"
    NULL_SENDER    = '<>'

    Q_VALUES       = ['Q','q']
    B_VALUES       = ['B','b']
  end
end
