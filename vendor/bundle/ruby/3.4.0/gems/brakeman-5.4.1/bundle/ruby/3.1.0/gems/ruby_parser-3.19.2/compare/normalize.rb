#!/usr/bin/env ruby -w

good = false

rules = Hash.new { |h,k| h[k] = [] }
rule = nil
order = []

def munge s
  renames = [
             # unquote... wtf?
             /`(.+?)'/,          proc { $1 },
             /"'(.+?)'"/,        proc { "\"#{$1}\"" },

             "'='",             "tEQL",
             "'!'",             "tBANG",
             "'%'",             "tPERCENT",
             "'&'",             "tAMPER2",
             "'('",             "tLPAREN2",
             "')'",             "tRPAREN",
             "'*'",             "tSTAR2",
             "'+'",             "tPLUS",
             "','",             "tCOMMA",
             "'-'",             "tMINUS",
             "'.'",             "tDOT",
             "'/'",             "tDIVIDE",
             "';'",             "tSEMI",
             "':'",             "tCOLON",
             "'<'",             "tLT",
             "'>'",             "tGT",
             "'?'",             "tEH",
             "'['",             "tLBRACK",
             "'\\n'",           "tNL",
             "']'",             "tRBRACK",
             "'^'",             "tCARET",
             "'`'",             "tBACK_REF2",
             "'{'",             "tLCURLY",
             "'|'",             "tPIPE",
             "'}'",             "tRCURLY",
             "'~'",             "tTILDE",
             '"["',             "tLBRACK",

             # 2.0 changes?
             '"<=>"',            "tCMP",
             '"=="',             "tEQ",
             '"==="',            "tEQQ",
             '"!~"',             "tNMATCH",
             '"=~"',             "tMATCH",
             '">="',             "tGEQ",
             '"<="',             "tLEQ",
             '"!="',             "tNEQ",
             '"<<"',             "tLSHFT",
             '">>"',             "tRSHFT",
             '"*"',              "tSTAR",

             '".."',             "tDOT2",

             '"&"',              "tAMPER",
             '"&&"',             "tANDOP",
             '"&."',             "tLONELY",
             '"||"',             "tOROP",

             '"..."',            "tDOT3",
             '"**"',             "tPOW",
             '"unary+"',         "tUPLUS",
             '"unary-"',         "tUMINUS",
             '"[]"',             "tAREF",
             '"[]="',            "tASET",
             '"::"',             "tCOLON2",
             '"{ arg"',          "tLBRACE_ARG",
             '"( arg"',          "tLPAREN_ARG",
             '"("',              "tLPAREN",
             'rparen',           "tRPAREN",
             '"{"',              "tLBRACE",
             '"=>"',             "tASSOC",
             '"->"',             "tLAMBDA",
             '":: at EXPR_BEG"', "tCOLON3",
             '"**arg"',          "tDSTAR",
             '","',              "tCOMMA",

             # other

             'tLBRACK2',        "tLBRACK", # HACK

             "' '",             "tSPACE", # needs to be later to avoid bad hits

             "%empty",          "none", # newer bison
             "/* empty */",     "none",
             /^\s*$/,           "none",

             "keyword_BEGIN",   "klBEGIN",
             "keyword_END",     "klEND",
             /keyword_(\w+)/,   proc { "k#{$1.upcase}" },
             /\bk_([a-z_]+)/,   proc { "k#{$1.upcase}" },
             /modifier_(\w+)/,  proc { "k#{$1.upcase}_MOD" },
             "kVARIABLE",       "keyword_variable", # ugh

             # 2.6 collapses klBEGIN to kBEGIN
             "klBEGIN",   "kBEGIN",
             "klEND",     "kEND",

             /keyword_(\w+)/,          proc { "k#{$1.upcase}" },
             /\bk_([^_][a-z_]+)/,      proc { "k#{$1.upcase}" },
             /modifier_(\w+)/,         proc { "k#{$1.upcase}_MOD" },

             "kVARIABLE",       "keyword_variable", # ugh: this is a rule name

             # 2.7 changes:

             '"global variable"',          "tGVAR",
             '"operator-assignment"',      "tOP_ASGN",
             '"back reference"',           "tBACK_REF",
             '"numbered reference"',       "tNTH_REF",
             '"local variable or method"', "tIDENTIFIER",
             '"constant"',                 "tCONSTANT",

             '"(.."',                  "tBDOT2",
             '"(..."',                 "tBDOT3",
             '"char literal"',         "tCHAR",
             '"literal content"',      "tSTRING_CONTENT",
             '"string literal"',       "tSTRING_BEG",
             '"symbol literal"',       "tSYMBEG",
             '"backtick literal"',     "tXSTRING_BEG",
             '"regexp literal"',       "tREGEXP_BEG",
             '"word list"',            "tWORDS_BEG",
             '"verbatim word list"',   "tQWORDS_BEG",
             '"symbol list"',          "tSYMBOLS_BEG",
             '"verbatim symbol list"', "tQSYMBOLS_BEG",

             '"float literal"',        "tFLOAT",
             '"imaginary literal"',    "tIMAGINARY",
             '"integer literal"',      "tINTEGER",
             '"rational literal"',     "tRATIONAL",

             '"instance variable"',  "tIVAR",
             '"class variable"',     "tCVAR",
             '"terminator"',         "tSTRING_END", # TODO: switch this?
             '"method"',             "tFID",
             '"}"',                  "tSTRING_DEND",

             '"do for block"',     "kDO_BLOCK",
             '"do for condition"', "kDO_COND",
             '"do for lambda"',    "kDO_LAMBDA",
             "tLABEL",             "kLABEL",

             # UGH
             "k_LINE__",       "k__LINE__",
             "k_FILE__",       "k__FILE__",
             "k_ENCODING__",   "k__ENCODING__",

             '"defined?"',     "kDEFINED",

             '"do (for condition)"', "kDO_COND",
             '"do (for lambda)"',    "kDO_LAMBDA",
             '"do (for block)"',     "kDO_BLOCK",

             /\"(\w+) \(?modifier\)?\"/, proc { |x| "k#{$1.upcase}_MOD" },
             /\"(\w+)\"/,                proc { |x| "k#{$1.upcase}" },

             /\$?@(\d+)(\s+|$)/,    "", # newer bison

             # TODO: remove for 3.0 work:
             "lex_ctxt ", "" # 3.0 production that's mostly noise right now
            ]

  renames.each_slice(2) do |(a, b)|
    if Proc === b then
      s.gsub!(a, &b)
    else
      s.gsub!(a, b)
    end
  end

  s.strip
end

ARGF.each_line do |line|
  next unless good or line =~ /^-* ?Grammar|\$accept : /

  case line.strip
  when /^$/ then
  when /^(\d+) (\$?[@\w]+): (.*)/ then    # yacc
    rule = $2
    order << rule unless rules.has_key? rule
    rules[rule] << munge($3)
  when /^(\d+) \s+\| (.*)/ then        # yacc
    rules[rule] << munge($2)
  when /^(\d+) (@\d+): (.*)/ then      # yacc
    rule = $2
    order << rule unless rules.has_key? rule
    rules[rule] << munge($3)
  when /^rule (\d+) (@?\w+):(.*)/ then # racc
    rule = $2
    order << rule unless rules.has_key? rule
    rules[rule] << munge($3)
  when /\$accept/ then                 # byacc?
    good = true
  when /Grammar/ then                  # both
    good = true
  when /^-+ Symbols/ then              # racc
    break
  when /^Terminals/ then               # yacc
    break
  when /^\cL/ then                     # byacc
    break
  else
    warn "unparsed: #{$.}: #{line.strip.inspect}"
  end
end

require 'yaml'

order.each do |k|
  next if k =~ /@/
  puts
  puts "#{k}:"
  puts rules[k].map { |r| "    #{r}" }.join "\n"
end
