require 'brakeman/checks/base_check'

#Checks for string interpolation and parameters in calls to
#Kernel#system, Kernel#exec, Kernel#syscall, and inside backticks.
#
#Examples of command injection vulnerabilities:
#
# system("rf -rf #{params[:file]}")
# exec(params[:command])
# `unlink #{params[:something}`
class Brakeman::CheckExecute < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds instances of possible command injection"

  SAFE_VALUES = [s(:const, :RAILS_ROOT),
                  s(:call, s(:const, :Rails), :root),
                  s(:call, s(:const, :Rails), :env),
                  s(:call, s(:const, :Process), :pid)]

  SHELL_ESCAPE_MODULE_METHODS = Set[:escape, :join, :shellescape, :shelljoin]
  SHELL_ESCAPE_MIXIN_METHODS = Set[:shellescape, :shelljoin]

  # These are common shells that are known to allow the execution of commands
  # via a -c flag. See dash_c_shell_command? for more info.
  KNOWN_SHELL_COMMANDS = Set["sh", "bash", "ksh", "csh", "tcsh", "zsh"]

  SHELLWORDS = s(:const, :Shellwords)

  #Check models, controllers, and views for command injection.
  def run_check
    Brakeman.debug "Finding system calls using ``"
    check_for_backticks tracker

    check_open_calls

    Brakeman.debug "Finding other system calls"
    calls = tracker.find_call :targets => [:IO, :Open3, :Kernel, :'POSIX::Spawn', :Process, nil],
      :methods => [:capture2, :capture2e, :capture3, :exec, :pipeline, :pipeline_r,
        :pipeline_rw, :pipeline_start, :pipeline_w, :popen, :popen2, :popen2e,
        :popen3, :spawn, :syscall, :system], :nested => true

    Brakeman.debug "Processing system calls"
    calls.each do |result|
      process_result result
    end
  end

  private

  #Processes results from Tracker#find_call.
  def process_result result
    call = result[:call]
    args = call.arglist
    first_arg = call.first_arg

    case call.method
    when :popen
      # Normally, if we're in a `popen` call, we only are worried about shell
      # injection when the argument is not an array, because array elements
      # are always escaped by Ruby. However, an exception is when the array
      # contains two values are something like "bash -c" because then the third
      # element is effectively the command being run and might be a malicious
      # executable if it comes (partially or fully) from user input.
      if !array?(first_arg)
        failure = include_user_input?(first_arg) ||
                  dangerous_interp?(first_arg) ||
                  dangerous_string_building?(first_arg)
      elsif dash_c_shell_command?(first_arg[1], first_arg[2])
        failure = include_user_input?(first_arg[3]) ||
                  dangerous_interp?(first_arg[3]) ||
                  dangerous_string_building?(first_arg[3])
      end
    when :system, :exec
      # Normally, if we're in a `system` or `exec` call, we only are worried
      # about shell injection when there's a single argument, because comma-
      # separated arguments are always escaped by Ruby. However, an exception is
      # when the first two arguments are something like "bash -c" because then
      # the third argument is effectively the command being run and might be
      # a malicious executable if it comes (partially or fully) from user input.
      if dash_c_shell_command?(first_arg, call.second_arg)
        failure = include_user_input?(args[3]) ||
                  dangerous_interp?(args[3]) ||
                  dangerous_string_building?(args[3])
      else
        failure = include_user_input?(first_arg) ||
                  dangerous_interp?(first_arg) ||
                  dangerous_string_building?(first_arg)
      end
    when :capture2, :capture2e, :capture3
      # Open3 capture methods can take a :stdin_data argument which is used as the
      # the input to the called command so it is not succeptable to command injection.
      # As such if the last argument is a hash (and therefore execution options) it
      # should be ignored

      args.pop if hash?(args.last) && args.length > 2
      failure = include_user_input?(args) ||
                dangerous_interp?(args) ||
                dangerous_string_building?(args)
    else
      failure = include_user_input?(args) ||
                dangerous_interp?(args) ||
                dangerous_string_building?(args)
    end

    if failure and original? result

      if failure.type == :interp #Not from user input
        confidence = :medium
      else
        confidence = :high
      end

      warn :result => result,
        :warning_type => "Command Injection",
        :warning_code => :command_injection,
        :message => "Possible command injection",
        :code => call,
        :user_input => failure,
        :confidence => confidence,
        :cwe_id => [77]
    end
  end

  # @return [Boolean] true iff the command given by `first_arg`, `second_arg`
  #   invokes a new shell process via `<shell_command> -c` (like `bash -c`)
  def dash_c_shell_command?(first_arg, second_arg)
    string?(first_arg) &&
    KNOWN_SHELL_COMMANDS.include?(first_arg.value) &&
    string?(second_arg) &&
    second_arg.value == "-c"
  end

  def check_open_calls
    tracker.find_call(:targets => [nil, :Kernel], :method => :open).each do |result|
      if match = dangerous_open_arg?(result[:call].first_arg)
        warn :result => result,
          :warning_type => "Command Injection",
          :warning_code => :command_injection,
          :message => msg("Possible command injection in ", msg_code("open")),
          :user_input => match,
          :confidence => :high,
          :cwe_id => [77]
      end
    end
  end

  def include_user_input? exp
    if node_type? exp, :arglist, :dstr, :evstr, :dxstr
      exp.each_sexp do |e|
        if res = include_user_input?(e)
          return res
        end
      end

      false
    else
      if shell_escape? exp
        false
      else
        super exp
      end
    end
  end

  def dangerous_open_arg? exp
    if string_interp? exp
      # Check for input at start of string
      exp[1] == "" and
        node_type? exp[2], :evstr and
        has_immediate_user_input? exp[2]
    else
      has_immediate_user_input? exp
    end
  end

  #Looks for calls using backticks such as
  #
  # `rm -rf #{params[:file]}`
  def check_for_backticks tracker
    tracker.find_call(:target => nil, :method => :`).each do |result|
      process_backticks result
    end
  end

  #Processes backticks.
  def process_backticks result
    return unless original? result

    exp = result[:call]

    if input = include_user_input?(exp)
      confidence = :high
    elsif input = dangerous?(exp)
      confidence = :medium
    else
      return
    end

    warn :result => result,
      :warning_type => "Command Injection",
      :warning_code => :command_injection,
      :message => "Possible command injection",
      :code => exp,
      :user_input => input,
      :confidence => confidence,
      :cwe_id => [77]
  end

  # This method expects a :dstr or :evstr node
  def dangerous? exp
    exp.each_sexp do |e|
      if call? e and e.method == :to_s
        e = e.target
      end

      next if node_type? e, :lit, :str
      next if SAFE_VALUES.include? e
      next if shell_escape? e
      next if temp_file_path? e

      if node_type? e, :if
        # If we're in a conditional, evaluate the `then` and `else` clauses to
        # see if they're dangerous.
        if res = dangerous?(e.sexp_body.sexp_body)
          return res
        end
      elsif node_type? e, :or, :evstr, :dstr
        if res = dangerous?(e)
          return res
        end
      else
        return e
      end
    end

    false
  end

  def dangerous_interp? exp
    match = include_interp? exp
    return unless match
    interp = match.match

    interp.each_sexp do |e|
      if res = dangerous?(e)
        return Match.new(:interp, res)
      end
    end

    false
  end

  #Checks if an expression contains string interpolation.
  #
  #Returns Match with :interp type if found.
  def include_interp? exp
    @string_interp = false
    process exp
    @string_interp
  end

  def dangerous_string_building? exp
    if string_building?(exp) && res = dangerous?(exp)
      return Match.new(:interp, res)
    end

    false
  end

  def shell_escape? exp
    return false unless call? exp

    if exp.target == SHELLWORDS and SHELL_ESCAPE_MODULE_METHODS.include? exp.method
      true
    elsif SHELL_ESCAPE_MIXIN_METHODS.include?(exp.method)
      true
    else
      false
    end
  end
end
