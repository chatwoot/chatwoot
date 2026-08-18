# Interactive runner for exercising a compiled Captain Routine against local account data.
#
# This executes real Routine actions, including customer-visible replies.
#
# Usage:
#   bundle exec rails runner script/run_captain_routine.rb
#   ACCOUNT_ID=1 bundle exec rails runner script/run_captain_routine.rb
#   ACCOUNT_ID=1 ROUTINE_ID=12 bundle exec rails runner script/run_captain_routine.rb

module CaptainRoutineRunTerminal
  extend self

  COLORS = {
    bold: 1, dim: 2, red: 31, green: 32, yellow: 33,
    blue: 34, magenta: 35, cyan: 36
  }.freeze

  def decorate(text, *styles)
    return text unless $stdout.tty? && ENV['NO_COLOR'].blank?

    codes = styles.map { |style| COLORS.fetch(style) }.join(';')
    "\e[#{codes}m#{text}\e[0m"
  end

  def stage(label, message, color = :cyan)
    puts "#{decorate(label.ljust(12), :bold, color)} #{message}"
  end

  def event(details)
    case details.fetch('type')
    when 'select' then select_event(details)
    when 'map' then map_event(details)
    when 'agent' then agent_event(details)
    when 'agent_tool' then agent_tool_event(details)
    when 'reduce' then reduce_event(details)
    end
  end

  private

  def select_event(details)
    message = if details.fetch('status') == 'started'
                "#{details.fetch('entity')} · selecting"
              else
                "#{details.fetch('entity')} · #{details.fetch('records')} records"
              end
    stage('SELECT', "#{message} #{path(details)}", :cyan)
  end

  def map_event(details)
    if details.fetch('status') == 'started'
      stage('MAP', "#{details.fetch('binding')} · #{details.fetch('records')} records #{path(details)}", :blue)
    else
      stage('MAP DONE', "#{details.fetch('results')} results collected #{path(details)}", :green)
    end
  end

  def agent_event(details)
    if details.fetch('status') == 'started'
      stage('AGENT', "conversation #{details.fetch('record_id')} · investigating #{path(details)}", :magenta)
    else
      outcome = decorate(details.fetch('outcome'), :bold)
      failed = details.fetch('status') == 'failed'
      stage(failed ? 'AGENT FAIL' : 'AGENT DONE',
            "conversation #{details.fetch('record_id')} · #{outcome} · #{details.fetch('receipts')} receipts #{path(details)}",
            failed ? :red : :green)
    end
  end

  def agent_tool_event(details)
    color = operation_color(details.fetch('effect'))
    label = details.fetch('effect') == 'read' ? 'TOOL' : 'ACTION'
    status = details.fetch('status') == 'completed' ? decorate('done', :green) : decorate('failed', :red)
    stage(label, "#{details.fetch('operation')} · #{status} · conversation #{details.fetch('record_id')} #{path(details)}", color)
  end

  def reduce_event(details)
    status = details.fetch('status') == 'started' ? 'summarizing' : 'summary ready'
    stage('REDUCE', "#{details.fetch('results')} results · #{status} #{path(details)}", :cyan)
  end

  def operation_color(effect)
    {
      'read' => :cyan,
      'internal_write' => :yellow,
      'customer_visible_write' => :red,
      'external_write' => :magenta
    }.fetch(effect, :blue)
  end

  def path(details)
    decorate("[#{details.fetch('path')}]", :dim)
  end
end

class CaptainRoutineRunWizard
  STEP_TYPES = %w[each reduce].freeze

  def initialize
    @terminal = CaptainRoutineRunTerminal
  end

  def perform
    print_header
    account = select_account
    routine = select_routine(account)
    show_routine(routine)
    confirm_run!(routine)
    run(routine)
  end

  private

  def print_header
    puts
    puts @terminal.decorate('Captain Routine Runner', :bold, :cyan)
    puts @terminal.decorate('Select and execute a validated Routine with live lifecycle logs.', :dim)
    puts
  end

  def select_account
    accounts = accounts_with_ready_routines
    abort 'No accounts have a ready Captain Routine.' if accounts.empty?

    print_accounts(accounts)
    account_id = ENV['ACCOUNT_ID'].presence || ask('Account ID', default: accounts.one? ? accounts.first.id : nil)
    accounts.find { |candidate| candidate.id == account_id.to_i } || abort("Account #{account_id.inspect} does not have a ready Routine.")
  end

  def print_accounts(accounts)
    @terminal.stage('ACCOUNTS', 'Ready Routines', :blue)
    accounts.each do |account|
      count = account.captain_routines.status_ready.count
      puts "  #{@terminal.decorate(account.id.to_s.rjust(4), :cyan)}  #{account.name} #{@terminal.decorate("· #{count} ready", :dim)}"
    end
    puts
  end

  def accounts_with_ready_routines
    Account.joins(:captain_routines)
           .where(captain_routines: { status: Captain::Routine.statuses.fetch('ready') })
           .distinct
           .order(:id)
           .to_a
  end

  def select_routine(account)
    routines = account.captain_routines.status_ready.order(:id).to_a
    print_routines(account, routines)
    routine_id = ENV['ROUTINE_ID'].presence || ask('Routine ID', default: routines.one? ? routines.first.id : nil)
    routines.find { |routine| routine.id == routine_id.to_i } || abort("Routine #{routine_id.inspect} is not ready for this account.")
  end

  def print_routines(account, routines)
    @terminal.stage('ROUTINES', "#{account.name} (#{account.id})", :blue)
    routines.each do |routine|
      title = routine.name.presence || routine.instructions.lines.first.strip
      schedule = routine.scheduled? ? "#{routine.cron_expression} · #{routine.timezone}" : 'on demand'
      puts "  #{@terminal.decorate(routine.id.to_s.rjust(4), :cyan)}  #{title}"
      puts "        #{@terminal.decorate(schedule, :dim)}"
    end
    puts
  end

  def show_routine(routine)
    puts
    @terminal.stage('ROUTINE', "#{routine.id} · #{routine.name || 'Untitled'}", :cyan)
    @terminal.stage('SCHEDULE', schedule_description(routine), :blue)
    @terminal.stage('INSTRUCTION', '')
    puts indent(routine.instructions)
    puts
    @terminal.stage('FLOW', "#{count_steps(routine.dsl.fetch('steps'))} executable steps", :blue)
    print_steps(routine.dsl.fetch('steps'))
    puts
  end

  def schedule_description(routine)
    routine.scheduled? ? "#{routine.cron_expression} · #{routine.timezone}" : 'On demand'
  end

  def print_steps(steps)
    steps.each_with_index do |step, index|
      prefix = format('%02d', index + 1)
      puts "#{@terminal.decorate(prefix, :dim)}  #{step_description(step)}"
    end
  end

  def step_description(step)
    type = STEP_TYPES.find { |candidate| step.key?(candidate) }
    type ? send("#{type}_description", step) : 'UNKNOWN'
  end

  def each_description(step)
    source = step.fetch('from')
    filters = source.fetch('where').present? ? source.fetch('where').inspect : 'all conversations'
    @terminal.decorate("EACH   #{step['each']} from #{source.fetch('select')} #{filters} → #{step.fetch('collect_as')}", :blue)
  end

  def reduce_description(step)
    @terminal.decorate("REDUCE #{step.dig('reduce', 'ref')} → #{step.fetch('save_as')}", :cyan)
  end

  def count_steps(steps)
    steps.length
  end

  def confirm_run!(routine)
    @terminal.stage('WARNING', 'This run executes the actions available to the Routine.', :red)
    answer = ask("Run Routine #{routine.id} now? [y/N]", allow_empty: true)
    abort 'Run cancelled.' unless answer.casecmp?('y') || answer.casecmp?('yes')
  end

  def run(routine)
    puts
    @terminal.stage('STARTING', "Routine #{routine.id}…", :green)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = routine.run!(on_step: ->(event) { @terminal.event(event) })
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    puts
    @terminal.stage('COMPLETED', "Execution #{result.fetch('id')} · #{format('%.2fs', elapsed)}", :green)
    @terminal.stage('TRACE', "#{result.fetch('trace').length} lifecycle events", :blue)
    print_bindings(result.fetch('bindings'))
  rescue StandardError => e
    puts
    @terminal.stage('FAILED', "#{e.class}: #{e.message}", :red)
    raise
  end

  def print_bindings(bindings)
    return if bindings.empty?

    @terminal.stage('OUTPUTS', '')
    bindings.each do |name, value|
      description = case value
                    when Array then "#{value.length} items"
                    when Hash then value.fetch('type', 'object')
                    else value.inspect
                    end
      puts "  #{@terminal.decorate(name, :cyan)} #{@terminal.decorate("· #{description}", :dim)}"
      puts indent(value.fetch('summary')) if value.is_a?(Hash) && value['summary'].present?
    end
  end

  def indent(value)
    value.lines.map { |line| "  #{line}" }.join
  end

  def ask(question, default: nil, allow_empty: false)
    prompt = default.present? ? "#{question} [#{default}]" : question
    loop do
      print "#{@terminal.decorate('?', :bold, :magenta)} #{@terminal.decorate(prompt, :bold)} #{@terminal.decorate('›', :dim)} "
      $stdout.flush
      answer = $stdin.gets
      abort '\nRun cancelled because input was closed.' if answer.nil?

      answer = answer.strip
      return default.to_s if answer.empty? && default.present?
      return answer if allow_empty || answer.present?

      puts @terminal.decorate('Please enter a value.', :yellow)
    end
  end
end

CaptainRoutineRunWizard.new.perform
