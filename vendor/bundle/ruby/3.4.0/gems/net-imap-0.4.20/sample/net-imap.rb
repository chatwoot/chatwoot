require 'net/imap'
require "getoptlong"

$stdout.sync = true
$port = nil
$user = ENV["USER"] || ENV["LOGNAME"]
$auth = "login"
$ssl = false
$starttls = false

def usage
  <<EOF
usage: #{$0} [options] <host>

  --help                        print this message
  --port=PORT                   specifies port
  --user=USER                   specifies user
  --auth=AUTH                   specifies auth type
  --starttls                    use starttls
  --ssl                         use ssl
EOF
end

begin
  require 'io/console'
rescue LoadError
  def _noecho(&block)
    system("stty", "-echo")
    begin
      yield STDIN
    ensure
      system("stty", "echo")
    end
  end
else
  def _noecho(&block)
    STDIN.noecho(&block)
  end
end

def get_password
  print "password: "
  begin
    return _noecho(&:gets).chomp
  ensure
    puts
  end
end

def get_command
  printf("%s@%s> ", $user, $host)
  if line = gets
    return line.strip.split(/\s+/)
  else
    return nil
  end
end

parser = GetoptLong.new
parser.set_options(['--debug', GetoptLong::NO_ARGUMENT],
  ['--help', GetoptLong::NO_ARGUMENT],
  ['--port', GetoptLong::REQUIRED_ARGUMENT],
  ['--user', GetoptLong::REQUIRED_ARGUMENT],
  ['--auth', GetoptLong::REQUIRED_ARGUMENT],
  ['--starttls', GetoptLong::NO_ARGUMENT],
  ['--ssl', GetoptLong::NO_ARGUMENT])
begin
  parser.each_option do |name, arg|
    case name
    when "--port"
      $port = arg
    when "--user"
      $user = arg
    when "--auth"
      $auth = arg
    when "--ssl"
      $ssl = true
    when "--starttls"
      $starttls = true
    when "--debug"
      Net::IMAP.debug = true
    when "--help"
      usage
      exit
    end
  end
rescue
  abort usage
end

$host = ARGV.shift
unless $host
  abort usage
end

imap = Net::IMAP.new($host, :port => $port, :ssl => $ssl)
begin
  imap.starttls if $starttls
  class << password = method(:get_password)
    alias to_str call
  end
  imap.authenticate($auth, $user, password)
  while true
    cmd, *args = get_command
    break unless cmd
    begin
      case cmd
      when "list"
        for mbox in imap.list("", args[0] || "*")
          if mbox.attr.include?(Net::IMAP::NOSELECT)
            prefix = "!"
          elsif mbox.attr.include?(Net::IMAP::MARKED)
            prefix = "*"
          else
            prefix = " "
          end
          print prefix, mbox.name, "\n"
        end
      when "select"
        imap.select(args[0] || "inbox")
        print "ok\n"
      when "close"
        imap.close
        print "ok\n"
      when "summary"
        unless messages = imap.responses["EXISTS"][-1]
          puts "not selected"
          next
        end
        if messages > 0
          for data in imap.fetch(1..-1, ["ENVELOPE"])
            print data.seqno, ": ", data.attr["ENVELOPE"].subject, "\n"
          end
        else
          puts "no message"
        end
      when "fetch"
        if args[0]
          data = imap.fetch(args[0].to_i, ["RFC822.HEADER", "RFC822.TEXT"])[0]
          puts data.attr["RFC822.HEADER"]
          puts data.attr["RFC822.TEXT"]
        else
          puts "missing argument"
        end
      when "logout", "exit", "quit"
        break
      when "help", "?"
        print <<EOF
list [pattern]                  list mailboxes
select [mailbox]                select mailbox
close                           close mailbox
summary                         display summary
fetch [msgno]                   display message
logout                          logout
help, ?                         display help message
EOF
      else
        print "unknown command: ", cmd, "\n"
      end
    rescue Net::IMAP::Error
      puts $!
    end
  end
ensure
  imap.logout
  imap.disconnect
end
