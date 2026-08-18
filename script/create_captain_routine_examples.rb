# Interactive setup wizard for exercising Captain Routine generation.
#
# Usage:
#   bundle exec rails runner script/create_captain_routine_examples.rb
#   ACCOUNT_ID=1 bundle exec rails runner script/create_captain_routine_examples.rb

require 'erb'
require 'fileutils'

module CaptainRoutineTerminalPresenter
  extend self

  COLORS = {
    bold: 1, dim: 2, red: 31, green: 32, yellow: 33,
    blue: 34, magenta: 35, cyan: 36
  }.freeze

  def call(event, details)
    handler = "print_#{event}"
    send(handler, details) if respond_to?(handler, true)
  end

  def stage(label, message, color)
    puts "#{decorate(label.ljust(12), :bold, color)} #{message}"
  end

  def document(label, value, color)
    puts
    puts decorate(label, :bold, color)
    puts JSON.pretty_generate(value)
    puts
  end

  def evaluation(label, result)
    color = evaluation_color(result.fetch('status'))
    stage(label, result.fetch('status').tr('_', ' ').upcase, color)
    puts "#{decorate('│', color)} #{result.fetch('summary')}"
    print_corrections(result.fetch('corrections', []))
    print_questions(result.fetch('questions', []))
    puts
  end

  def decorate(text, *styles)
    return text unless $stdout.tty? && ENV['NO_COLOR'].blank?

    codes = styles.map { |style| COLORS.fetch(style) }.join(';')
    "\e[#{codes}m#{text}\e[0m"
  end

  private

  def print_compiling_dsl(details)
    if details[:repairing]
      stage('SELF-HEAL', "Rebuilding DSL from validation or review feedback (#{attempt(details)})…", :yellow)
    else
      stage('GENERATING', "Building DSL directly from the instruction (#{attempt(details)})…", :blue)
    end
  end

  def print_dsl_compiled(details)
    document('COMPILED DSL', details.fetch(:dsl), :cyan)
  end

  def print_validating_dsl(_details)
    stage('VALIDATING', 'Checking schema, selection filters, bindings, and reduction references…', :magenta)
  end

  def print_dsl_validated(details)
    evaluation('DSL RESULT', details.fetch(:evaluation))
  end

  def print_evaluating_dsl(_details)
    stage('DSL CHECK', 'Comparing the candidate DSL with the original instruction…', :magenta)
  end

  def print_dsl_evaluated(details)
    evaluation('DSL INTENT', details.fetch(:evaluation))
  end

  def attempt(details)
    "#{details[:attempt]}/#{details[:maximum]}"
  end

  def print_corrections(corrections)
    corrections.each_with_index do |correction, index|
      puts "#{decorate('├─', :yellow)} Repair #{index + 1}: #{correction['problem']}"
      puts "#{decorate('│ ', :yellow)}   #{decorate(correction['suggestion'], :dim)}"
    end
  end

  def print_questions(questions)
    questions.each_with_index do |question, index|
      puts "#{decorate('├─', :magenta)} Question #{index + 1}: #{question['question']}"
    end
  end

  def evaluation_color(status)
    {
      'valid' => :green,
      'correctable' => :yellow,
      'needs_clarification' => :magenta,
      'unsupported' => :red
    }.fetch(status, :red)
  end
end

module CaptainRoutineHtmlSteps
  extend self

  ICONS = {
    'loop' => '<path d="m17 2 4 4-4 4"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><path d="m7 22-4-4 4-4"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/>',
    'reduction' => '<path d="M4 5h16"/><path d="M7 10h10"/><path d="M10 15h4"/><path d="M12 15v5"/>',
    'step' => '<circle cx="12" cy="12" r="9"/><path d="M12 8v8"/><path d="M8 12h8"/>'
  }.freeze

  def render(steps)
    steps.each_with_index.map { |step, index| step_html(step, index + 1) }.join
  end

  private

  def step_html(step, position)
    type, title = step_identity(step)
    <<~HTML
      <details class="step #{type}" open>
        <summary class="step-head"><span class="number">#{format('%02d', position)}</span><span class="icon">#{icon(type)}</span><span class="kind">#{escape(type)}</span><strong>#{escape(title)}</strong><span class="disclosure" aria-hidden="true"></span></summary>
        <div class="step-body">#{step_details(step)}</div>
      </details>
    HTML
  end

  def step_identity(step)
    return ['loop', "For each #{step['each']}"] if step['each']
    return ['reduction', "Reduce #{step.dig('reduce', 'ref')}"] if step['reduce']

    ['step', 'Unknown step']
  end

  def step_details(step)
    run = step.fetch('run', {})
    orchestration = step.except('run', 'do', 'else')
    <<~HTML
      <div class="step-metadata">
        <span class="kicker">Orchestration</span>
        <pre>#{escape(JSON.pretty_generate(orchestration))}</pre>
      </div>
      <div class="agent-instruction">
        <div class="instruction-head"><span class="kicker">Agent instruction</span><code>#{escape(run['agent'])}</code></div>
        <pre>#{escape(run['instruction'])}</pre>
      </div>
      #{result_contract_details(run['result'])}
    HTML
  end

  def result_contract_details(contract)
    return '' unless contract

    <<~HTML
      <div class="step-metadata">
        <span class="kicker">Result contract</span>
        <pre>#{escape(JSON.pretty_generate(contract))}</pre>
      </div>
    HTML
  end

  def icon(type)
    <<~HTML.squish
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{ICONS.fetch(type)}</svg>
    HTML
  end

  def escape(value)
    ERB::Util.html_escape(value.to_s)
  end
end

# The standalone renderer keeps its markup and visual system together so the generated artifact has no runtime dependencies.
# rubocop:disable Metrics/ModuleLength
module CaptainRoutineHtmlRenderer
  extend self

  ICONS = {
    'routine' => '<path d="M4 6h16"/><path d="M4 12h10"/><path d="M4 18h13"/><circle cx="19" cy="12" r="2"/>',
    'schedule' => '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    'expand' => '<path d="M8 3H3v5"/><path d="M16 3h5v5"/><path d="M8 21H3v-5"/><path d="M16 21h5v-5"/>',
    'collapse' => '<path d="M3 8h5V3"/><path d="M21 8h-5V3"/><path d="M3 16h5v5"/><path d="M21 16h-5v5"/>'
  }.freeze

  def write(routine)
    path = Rails.root.join('tmp', "routine-#{routine.id}.html")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, page(routine.reload))
    path
  end

  private

  def page(routine)
    <<~HTML
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Routine #{routine.id} · #{escape(routine.name || 'Untitled')}</title>
        <style>#{styles}</style>
      </head>
      <body>
        <main>
          #{page_header(routine)}
          <div class="edition-line"><span>Model schedule</span><i aria-hidden="true"></i><span>Direct generation</span><i aria-hidden="true"></i><span>Reviewed DSL</span></div>
          #{instruction_section(routine)}
          #{invocation_section(routine)}
          #{flow_section(routine.dsl)}
          #{timeline_section(routine.build_log)}
          #{raw_section('05', 'Compiled DSL', routine.dsl)}
        </main>
        <script>
          function setSteps(open) {
            document.querySelectorAll('details.step').forEach(function(step) { step.open = open; });
          }
        </script>
      </body>
      </html>
    HTML
  end

  def page_header(routine)
    <<~HTML
      <header>
        <div class="identity"><span class="brand-mark">#{icon('routine')}</span><div><span class="eyebrow">CAPTAIN / ROUTINE #{format('%02d', routine.id)}</span><h1>#{escape(routine.name || 'Untitled routine')}</h1></div></div>
        <span class="status #{escape(routine.status)}"><span class="status-indicator" aria-hidden="true"></span>#{escape(routine.status.tr('_', ' '))}</span>
      </header>
    HTML
  end

  def instruction_section(routine)
    <<~HTML
      <section class="panel instruction">#{section_heading('01', 'Source', 'Original instruction')}<p>#{escape(routine.instructions)}</p></section>
    HTML
  end

  def invocation_section(routine)
    mode = routine.scheduled? ? 'Scheduled' : 'On demand'
    expression = routine.cron_expression.presence || 'No recurring schedule'
    <<~HTML
      <section class="panel invocation-panel">
        #{section_heading('02', 'Invocation', 'Run policy')}
        <div class="invocation"><span class="invocation-icon">#{icon('schedule')}</span><div><span class="kicker">Mode</span><strong>#{mode}</strong></div><div><span class="kicker">Cron expression</span><code>#{escape(expression)}</code></div><div><span class="kicker">Timezone</span><code>#{escape(routine.timezone)}</code></div></div>
      </section>
    HTML
  end

  def flow_section(dsl)
    if dsl.blank?
      return <<~HTML
        <section class="panel">#{section_heading('03', 'Structure', 'Routine map')}<p class="muted">No DSL has been compiled yet.</p></section>
      HTML
    end

    controls = <<~HTML.squish
      <div class="controls"><button type="button" onclick="setSteps(true)">#{icon('expand')}<span>Expand all</span></button><button type="button" onclick="setSteps(false)">#{icon('collapse')}<span>Collapse all</span></button></div>
    HTML
    <<~HTML
      <section class="panel flow-panel">
        #{section_heading('03', 'Structure', 'Routine map', controls)}
        <div class="flow">#{CaptainRoutineHtmlSteps.render(dsl.fetch('steps', []))}</div>
      </section>
    HTML
  end

  def timeline_section(build_log)
    items = build_log.map do |entry|
      status = entry.dig('evaluation', 'status') || 'unknown'
      summary = entry.dig('evaluation', 'summary')
      <<~HTML
        <li><span class="dot #{escape(status)}"></span><div><strong>#{escape(entry['phase'] || 'legacy')}</strong>
        <small>Pass #{entry['iteration']} · #{escape(status.tr('_', ' '))}</small><p>#{escape(summary)}</p></div></li>
      HTML
    end.join
    "<section class=\"panel lifecycle\">#{section_heading('04', 'Trace', 'Build lifecycle')}<ol class=\"timeline\">#{items}</ol></section>"
  end

  def raw_section(number, title, value)
    return '' if value.blank?

    <<~HTML
      <details class="raw-panel">
        <summary><span class="section-index">#{number}</span><span><span class="kicker">Artifact</span><strong>#{escape(title)}</strong></span><span class="disclosure" aria-hidden="true"></span></summary>
        <pre>#{escape(JSON.pretty_generate(value))}</pre>
      </details>
    HTML
  end

  def section_heading(number, kicker, title, controls = nil)
    <<~HTML.squish
      <div class="section-head"><div class="section-title"><span class="section-index">#{number}</span><div><span class="kicker">#{escape(kicker)}</span><h2>#{escape(title)}</h2></div></div>#{controls}</div>
    HTML
  end

  def icon(name)
    <<~HTML.squish
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{ICONS.fetch(name)}</svg>
    HTML
  end

  def escape(value)
    ERB::Util.html_escape(value.to_s)
  end

  def styles
    <<~CSS
      :root {
        color-scheme: light;
        --paper: #f8fafc;
        --panel: rgba(255, 255, 255, .94);
        --ink: #16202f;
        --muted: #66758a;
        --rule: #dce4ed;
        --rule-strong: #b9c9da;
        --blue: #315f8c;
        --blue-soft: #edf3f8;
        --cyan: #3c7582;
        --green: #31705a;
        --yellow: #987443;
        --red: #99505a;
        --violet: #6c6287;
        --mono: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
      }

      * { box-sizing: border-box; }
      body {
        margin: 0;
        color: var(--ink);
        font: 400 15px/1.6 Inter, "Helvetica Neue", Arial, sans-serif;
        background-color: var(--paper);
        background-image:
          linear-gradient(rgba(49, 95, 140, .035) 1px, transparent 1px),
          linear-gradient(90deg, rgba(49, 95, 140, .035) 1px, transparent 1px),
          linear-gradient(rgba(49, 95, 140, .018) 1px, transparent 1px),
          linear-gradient(90deg, rgba(49, 95, 140, .018) 1px, transparent 1px);
        background-size: 32px 32px, 32px 32px, 160px 160px, 160px 160px;
      }
      main { width: 100%; padding: clamp(28px, 4vw, 64px) clamp(20px, 4vw, 64px) 112px; }
      svg { display: block; width: 18px; height: 18px; }
      header { display: flex; align-items: flex-start; justify-content: space-between; gap: 32px; padding-bottom: 30px; }
      .identity { display: flex; align-items: flex-start; gap: 18px; min-width: 0; }
      .brand-mark { display: grid; flex: 0 0 40px; width: 40px; height: 40px; place-items: center; border: 1px solid var(--rule-strong); color: var(--blue); background: var(--panel); }
      .brand-mark svg { width: 20px; height: 20px; }
      .eyebrow, .kicker, .kind, .section-index, .status, .invocation code {
        font-family: var(--mono);
        letter-spacing: .08em;
        text-transform: uppercase;
      }
      .eyebrow { display: block; margin: 1px 0 7px; color: var(--blue); font-size: 11px; font-weight: 500; }
      h1 { max-width: 1000px; margin: 0; font-size: clamp(28px, 3vw, 44px); font-weight: 400; line-height: 1.12; letter-spacing: -.025em; }
      h2 { margin: 1px 0 0; font-size: 18px; font-weight: 500; line-height: 1.3; }
      .status { display: inline-flex; align-items: center; gap: 8px; flex: 0 0 auto; padding: 8px 11px; border: 1px solid var(--rule-strong); color: var(--muted); background: var(--panel); font-size: 10px; font-weight: 500; }
      .status-indicator { width: 6px; height: 6px; background: currentColor; }
      .status.ready { color: var(--green); border-color: color-mix(in srgb, var(--green) 45%, var(--rule)); }
      .edition-line { display: grid; grid-template-columns: max-content 1fr max-content 1fr max-content; align-items: center; gap: 16px; margin-bottom: 22px; color: var(--muted); font: 500 10px/1 var(--mono); letter-spacing: .1em; text-transform: uppercase; }
      .edition-line i { display: block; height: 1px; background: var(--rule-strong); }
      .panel, .raw-panel { margin: 0 0 18px; border: 1px solid var(--rule); background: var(--panel); }
      .panel { padding: clamp(22px, 2.5vw, 36px); }
      .section-head { display: flex; align-items: center; justify-content: space-between; gap: 24px; margin-bottom: 24px; }
      .section-title { display: flex; align-items: center; gap: 15px; }
      .section-index { color: var(--blue); font-size: 10px; font-weight: 500; }
      .kicker { display: block; color: var(--muted); font-size: 9px; font-weight: 500; }
      .instruction p { max-width: 1120px; margin: 0; white-space: pre-wrap; color: #344256; font-size: 16px; line-height: 1.72; }
      .controls { display: flex; gap: 1px; border: 1px solid var(--rule-strong); background: var(--rule-strong); }
      .controls button { display: inline-flex; align-items: center; gap: 8px; border: 0; padding: 9px 12px; color: var(--ink); background: #fff; font: 500 10px/1 var(--mono); letter-spacing: .04em; cursor: pointer; }
      .controls button:hover { color: var(--blue); background: var(--blue-soft); }
      .controls button:focus-visible { outline: 2px solid var(--blue); outline-offset: 2px; }
      .controls svg { width: 14px; height: 14px; }
      .invocation { display: grid; grid-template-columns: 38px repeat(3, minmax(150px, 1fr)); align-items: center; gap: 22px; padding: 16px; border: 1px solid var(--rule-strong); border-left: 2px solid var(--blue); background: var(--blue-soft); }
      .invocation-icon { display: grid; width: 32px; height: 32px; place-items: center; border-right: 1px solid var(--rule-strong); color: var(--blue); }
      .invocation-icon svg { width: 16px; height: 16px; }
      .invocation strong { display: block; font-weight: 500; }
      .invocation code { display: block; margin-top: 2px; color: var(--ink); font-size: 11px; letter-spacing: 0; text-transform: none; overflow-wrap: anywhere; }
      .flow { margin: 26px 0 0 16px; padding-left: 26px; border-left: 1px solid var(--rule-strong); }
      .step { position: relative; margin: 12px 0; border: 1px solid var(--rule); border-left: 2px solid var(--blue); background: #fff; }
      .step::before { position: absolute; top: 25px; left: -28px; width: 26px; border-top: 1px solid var(--rule-strong); content: ""; }
      .step.loop { border-left-color: var(--cyan); }
      .step.reduction { border-left-color: var(--violet); }
      .step-head { display: grid; grid-template-columns: 30px 20px minmax(72px, max-content) minmax(0, 1fr) 18px; align-items: center; gap: 11px; min-height: 50px; padding: 10px 14px; cursor: pointer; list-style: none; }
      .step-head::-webkit-details-marker, .raw-panel > summary::-webkit-details-marker { display: none; }
      .number { color: var(--muted); font: 400 10px/1 var(--mono); }
      .icon { color: var(--blue); }
      .icon svg { width: 16px; height: 16px; }
      .kind { color: var(--muted); font-size: 9px; font-weight: 500; }
      .step-head strong { min-width: 0; overflow-wrap: anywhere; font-weight: 500; }
      .disclosure { position: relative; width: 14px; height: 14px; color: var(--muted); }
      .disclosure::before, .disclosure::after { position: absolute; top: 6px; left: 2px; width: 10px; height: 1px; background: currentColor; content: ""; transition: transform .16s ease; }
      details:not([open]) > summary .disclosure::after { transform: rotate(90deg); }
      .step-body { padding: 0 14px 14px 75px; border-top: 1px solid var(--rule); }
      pre { overflow: auto; margin: 14px 0 0; padding: 16px; border-left: 1px solid var(--rule-strong); color: #334155; background: #f8fafc; font: 400 12px/1.65 var(--mono); }
      .step-metadata, .agent-instruction { margin-top: 14px; }
      .step-metadata pre { margin-top: 6px; }
      .instruction-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
      .instruction-head code { color: var(--blue); font: 500 12px/1.4 var(--mono); }
      .agent-instruction pre { margin-top: 6px; white-space: pre-wrap; overflow-wrap: anywhere; color: var(--ink); font-family: inherit; font-size: 14px; line-height: 1.7; }
      .timeline { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 0; margin: 0; padding: 0; list-style: none; border-top: 1px solid var(--rule); }
      .timeline li { display: grid; grid-template-columns: 12px 1fr; gap: 12px; padding: 18px 20px 18px 0; border-bottom: 1px solid var(--rule); }
      .timeline .dot { width: 7px; height: 7px; margin-top: 7px; border: 1px solid var(--yellow); background: transparent; }
      .timeline .dot.valid { border-color: var(--green); background: var(--green); }
      .timeline .dot.failed, .timeline .dot.unsupported { border-color: var(--red); background: var(--red); }
      .timeline strong { display: block; font: 500 11px/1.5 var(--mono); text-transform: capitalize; }
      .timeline small, .timeline p, .muted { color: var(--muted); }
      .timeline small { font: 400 10px/1.5 var(--mono); }
      .timeline p { margin: 7px 0 0; font-size: 13px; line-height: 1.5; }
      .raw-panel > summary { display: grid; grid-template-columns: 30px 1fr 18px; align-items: center; gap: 15px; min-height: 68px; padding: 14px clamp(22px, 2.5vw, 36px); cursor: pointer; list-style: none; }
      .raw-panel > summary strong { display: block; margin-top: 2px; font-weight: 500; }
      .raw-panel > pre { margin: 0; border: 0; border-top: 1px solid var(--rule); padding: clamp(20px, 2.5vw, 36px); }

      @media (max-width: 700px) {
        main { padding-bottom: 64px; }
        header { display: block; }
        .status { margin-top: 20px; }
        .section-head { align-items: flex-start; }
        .controls { margin-top: 2px; }
        .controls button span { display: none; }
        .edition-line { grid-template-columns: 1fr; gap: 8px; }
        .edition-line i { display: none; }
        .invocation { grid-template-columns: 32px 1fr; }
        .invocation > div { grid-column: 2; }
        .flow { margin-left: 8px; padding-left: 18px; }
        .step::before { left: -20px; width: 18px; }
        .step-head { grid-template-columns: 24px 18px minmax(0, 1fr) 18px; }
        .step-head .kind { display: none; }
        .step-body { padding-left: 14px; }
      }

      @media (prefers-reduced-motion: reduce) {
        .disclosure::after { transition: none; }
      }
    CSS
  end
end
# rubocop:enable Metrics/ModuleLength

module CaptainRoutineExampleInstructions
  REFUND = <<~TEXT.strip.freeze
    Go through all conversations tagged `refund`.

    For each conversation, review the messages and customer details and look up their payment in Stripe. If there isn't enough
    information to find the payment, ask the customer for what is missing.

    Issue a refund if the customer accidentally paid twice, or if they were charged after a free trial they meant to cancel.
    Otherwise, add a private note explaining why the refund was rejected.

    When finished, summarize the refunds and rejections, explain the reasons, list any conversations still waiting for
    information, and tell me the most common reason customers requested a refund.
  TEXT
end

class CaptainRoutineExamplesWizard
  INSTRUCTIONS = [CaptainRoutineExampleInstructions::REFUND].freeze

  def initialize
    @terminal = CaptainRoutineTerminalPresenter
    @html = CaptainRoutineHtmlRenderer
  end

  def perform
    print_header
    account = select_account
    confirm_account!(account)
    label = account.labels.find_or_create_by!(title: 'refund') do |record|
      record.description = 'Marks conversations for the Captain refund Routine.'
    end
    @terminal.stage('LABEL', "#{label.title} (#{label.id}) is available for deterministic selection.", :green)
    routines = INSTRUCTIONS.each_with_index.map { |instructions, index| build_routine(account, instructions, index + 1) }
    print_summary(routines)
  end

  private

  def print_header
    puts
    puts @terminal.decorate('Captain Routine Setup', :bold, :cyan)
    puts @terminal.decorate('Generate, validate, review, repair, and visualize a Routine DSL.', :dim)
    puts
  end

  def select_account
    account_id = ENV['ACCOUNT_ID'].presence || ask('Enter the account ID')
    loop do
      account = Account.find_by(id: account_id)
      return account if account

      puts "No account found with ID #{account_id.inspect}."
      account_id = ask('Enter the account ID')
    end
  end

  def confirm_account!(account)
    @terminal.stage('ACCOUNT', "#{account.name} (#{account.id})", :blue)
    answer = ask("Use #{account.name} (account #{account.id})? [y/N]", allow_empty: true)
    abort 'Setup cancelled.' unless answer.casecmp?('y') || answer.casecmp?('yes')
  end

  def build_routine(account, instructions, position)
    routine = account.captain_routines.where(instructions: instructions).order(:id).first_or_create!
    puts
    @terminal.stage('ROUTINE', "#{position}/#{INSTRUCTIONS.size} · ID #{routine.id}", :cyan)
    puts @terminal.decorate(instructions, :dim)
    puts
    configure_schedule(routine)
    puts
    generate_until_settled(routine)
    routine.reload
  end

  def configure_schedule(routine)
    @terminal.stage('SCHEDULE', 'Configured on the Routine model and excluded from its DSL.', :blue)

    loop do
      cron_expression = ask('Cron expression (blank for on-demand)', allow_empty: true).presence
      timezone = cron_expression.present? ? schedule_timezone(routine) : routine.timezone
      routine.assign_attributes(cron_expression: cron_expression, timezone: timezone)

      if routine.save
        description = routine.scheduled? ? "#{routine.cron_expression} · #{routine.timezone}" : 'On demand'
        @terminal.stage('RUN POLICY', description, :green)
        return
      end

      @terminal.stage('INVALID', routine.errors.full_messages.to_sentence, :red)
    end
  end

  def schedule_timezone(routine)
    default_timezone = if routine.scheduled?
                         routine.timezone
                       else
                         routine.account.reporting_timezone.presence || 'UTC'
                       end
    ask("Timezone [#{default_timezone}]", allow_empty: true).presence || default_timezone
  end

  def generate_until_settled(routine)
    attempted_build = false
    loop do
      outcome = handle_status(routine.reload, attempted_build)
      return if outcome == :finished

      attempted_build = true if outcome == :built
    end
  end

  def handle_status(routine, attempted_build)
    return print_ready_routine(routine) if routine.status_ready?
    return answer_questions(routine) if routine.status_awaiting_clarification?
    return print_unresolved_routine(routine) if attempted_build && (routine.status_needs_review? || routine.status_failed?)

    run_builder(routine)
    :built
  end

  def answer_questions(routine)
    @terminal.stage('CLARIFY', 'Captain needs more information', :magenta)
    answers = routine.clarification_questions.each_with_index.to_h do |question, index|
      [question.fetch('id'), ask_clarification(question, index + 1)]
    end
    run_builder(routine, answers: answers)
    :built
  end

  def ask_clarification(question, position)
    puts @terminal.decorate("  #{question['reason']}", :dim) if question['reason'].present?
    suggestions = Array(question['suggested_answers'])
    print_suggested_answers(suggestions)

    prompt = "#{position}. #{question.fetch('question')}"
    prompt += ' (choose a number or type an answer)' if suggestions.any?
    answer = ask(prompt)
    selected_answer(suggestions, answer)
  end

  def print_suggested_answers(suggestions)
    suggestions.each_with_index do |suggestion, index|
      label = suggestion.is_a?(Hash) ? suggestion['label'] : suggestion.to_s
      puts "  #{@terminal.decorate((index + 1).to_s.rjust(2), :cyan)}  #{label}"
    end
  end

  def selected_answer(suggestions, answer)
    return answer unless answer.match?(/\A\d+\z/) && answer.to_i.between?(1, suggestions.length)

    suggestion = suggestions.fetch(answer.to_i - 1)
    suggestion.is_a?(Hash) ? suggestion.fetch('answer', suggestion['label']) : suggestion
  end

  def run_builder(routine, answers: {})
    callback = lambda do |event, details|
      @terminal.call(event, details)
      visualize(routine) if event == :dsl_compiled
    end
    routine.build_dsl!(answers: answers, on_stage: callback)
  end

  def visualize(routine)
    path = @html.write(routine)
    @terminal.stage('VISUALIZED', path.relative_path_from(Rails.root).to_s, :cyan)
  rescue StandardError => e
    @terminal.stage('VISUALIZE', "Could not write HTML: #{e.message}", :red)
  end

  def print_ready_routine(routine)
    @terminal.stage('READY', "Validated after #{routine.build_iterations} lifecycle passes", :green)
    visualize(routine)
    :finished
  end

  def print_unresolved_routine(routine)
    @terminal.stage(routine.status.upcase, 'The routine requires review', :red)
    puts JSON.pretty_generate(routine.evaluation)
    visualize(routine) if routine.dsl.present?
    :finished
  end

  def print_summary(routines)
    puts
    puts @terminal.decorate('Setup complete', :bold, :cyan)
    routines.each do |routine|
      color = routine.status_ready? ? :green : :yellow
      puts "#{@terminal.decorate('●', color)} #{routine.id}: #{routine.status} — #{routine.name || routine.instructions.lines.first.strip}"
    end
  end

  def ask(question, allow_empty: false)
    loop do
      print "#{@terminal.decorate('?', :bold, :magenta)} #{@terminal.decorate(question, :bold)} #{@terminal.decorate('›', :dim)} "
      $stdout.flush
      answer = $stdin.gets
      abort '\nSetup cancelled because input was closed.' if answer.nil?

      answer = answer.strip
      return answer if allow_empty || answer.present?

      puts @terminal.decorate('Please enter a value.', :yellow)
    end
  end
end

CaptainRoutineExamplesWizard.new.perform unless ENV['SKIP_CAPTAIN_ROUTINE_WIZARD'] == 'true'
