#!/usr/bin/env ruby -ws

$b ||= false # bug mode -- ripper is buggy, use Ripper.sexp
$d ||= false # debug -- turn on yydebug
$p ||= false # Use pp

require "ripper/sexp"
require "pp" if $p

if ARGV.empty? then
  warn "reading from stdin"
  ARGV << "-"
end

class MySexpBuilder < Ripper::SexpBuilderPP
  def on_parse_error msg
    Kernel.warn msg
  end
end

ARGV.each do |path|
  src = path == "-" ? $stdin.read : File.read(path)

  sexp = if $b then
           Ripper.sexp src
         else
           rip = MySexpBuilder.new src
           rip.yydebug = $d
           rip.parse

           if rip.error? then
             warn "skipping"
             next
           end
         end

  puts "accept"

  if $p then
    pp sexp
  else
    p sexp
  end
end
