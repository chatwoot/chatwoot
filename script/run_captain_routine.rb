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
    when 'operation' then operation_event(details)
    when 'each' then each_event(details)
    when 'decide' then decision_event(details)
    when 'compose' then compose_event(details)
    when 'when' then condition_event(details)
    end
  end

  private

  def operation_event(details)
    color = operation_color(details.fetch('effect'))
    label = details.fetch('effect') == 'read' ? 'QUERY' : 'ACTION'
    status = details.fetch('status') == 'started' ? decorate('running', :dim) : decorate('done', :green)
    stage(label, "#{details.fetch('operation')} · #{status} #{path(details)}", color)
  end

  def each_event(details)
    if details.fetch('status') == 'started'
      stage('EACH', "#{details.fetch('binding')} · #{details.fetch('items')} items #{path(details)}", :blue)
    else
      stage('EACH DONE', "#{details.fetch('items')} items processed #{path(details)}", :green)
    end
  end

  def decision_event(details)
    if details.fetch('status') == 'started'
      stage('DECIDE', "#{details.fetch('decision')} · evaluating #{path(details)}", :magenta)
    else
      stage('DECIDED', "#{details.fetch('decision')} → #{decorate(details.fetch('choice'), :bold)} #{path(details)}", :magenta)
    end
  end

  def compose_event(details)
    if details.fetch('status') == 'started'
      stage('COMPOSE', "#{details.fetch('composition')} · drafting #{path(details)}", :cyan)
    else
      stage('COMPOSED', "#{details.fetch('composition')} · #{details.fetch('segments')} segments #{path(details)}", :green)
    end
  end

  def condition_event(details)
    outcome = details.fetch('matched') ? decorate('matched', :green) : decorate('not matched', :dim)
    stage('WHEN', "#{outcome} · #{details.fetch('branch').upcase} branch #{path(details)}", :yellow)
  end

  def operation_color(effect)
    { 'read' => :cyan, 'internal_write' => :yellow, 'customer_visible_write' => :red }.fetch(effect, :blue)
  end

  def path(details)
    decorate("[#{details.fetch('path')}]", :dim)
  end
end

class CaptainRoutineRunWizard
  STEP_TYPES = %w[operation each decide compose when].freeze

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

  def print_steps(steps, depth = 0)
    steps.each_with_index do |step, index|
      prefix = "#{'  ' * depth}#{format('%02d', index + 1)}"
      puts "#{@terminal.decorate(prefix, :dim)}  #{step_description(step)}"
      print_steps(step.fetch('do'), depth + 1) if step['do'].present?
      if step['else'].present?
        puts "#{'  ' * (depth + 1)}#{@terminal.decorate('ELSE', :dim)}"
        print_steps(step.fetch('else'), depth + 1)
      end
    end
  end

  def step_description(step)
    type = STEP_TYPES.find { |candidate| step.key?(candidate) }
    type ? send("#{type}_description", step) : 'UNKNOWN'
  end

  def operation_description(step)
    operation = Captain::Routines::Operations::Registry.fetch(step.fetch('operation'))
    binding = step['save_as'].present? ? " → #{step['save_as']}" : ''
    color = operation.kind == 'query' ? :cyan : action_color(operation.effect)
    @terminal.decorate("#{operation.kind.upcase}  #{step['operation']}#{binding}", color)
  end

  def each_description(step)
    @terminal.decorate("EACH   #{step['each']} from #{source_name(step.fetch('from'))}", :blue)
  end

  def decide_description(step)
    @terminal.decorate("DECIDE #{step['decide']} → #{step['choices'].join(' / ')}", :magenta)
  end

  def compose_description(step)
    @terminal.decorate("COMPOSE #{step['compose']} → rich_message", :cyan)
  end

  def when_description(step)
    @terminal.decorate("WHEN   #{step.dig('when', 'ref')} == #{step.dig('when', 'equals').inspect}", :yellow)
  end

  def source_name(source)
    source['ref'] || source['operation']
  end

  def action_color(effect)
    effect == 'customer_visible_write' ? :red : :yellow
  end

  def count_steps(steps)
    steps.sum { |step| 1 + count_steps(step.fetch('do', [])) + count_steps(step.fetch('else', [])) }
  end

  def confirm_run!(routine)
    @terminal.stage('WARNING', 'This run performs real internal and customer-visible actions.', :red)
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
