# frozen_string_literal: true

# Configuration for RubyLLM::Agents
#
# For more information, see: https://github.com/adham90/ruby_llm-agents

RubyLLM::Agents.configure do |config|
  # ============================================
  # Model Defaults
  # ============================================

  # Default LLM model for all agents (can be overridden per agent with `model "model-name"`)
  # config.default_model = "gemini-2.0-flash"

  # Default temperature (0.0 = deterministic, 2.0 = creative)
  # config.default_temperature = 0.0

  # Default timeout in seconds for each LLM request
  # config.default_timeout = 60

  # Enable streaming by default for all agents
  # When enabled, agents stream responses and track time-to-first-token
  # config.default_streaming = false

  # ============================================
  # Caching
  # ============================================

  # Cache store for agent response caching (defaults to Rails.cache)
  # config.cache_store = Rails.cache
  # config.cache_store = ActiveSupport::Cache::MemoryStore.new

  # ============================================
  # Execution Logging
  # ============================================

  # Async logging via background job (recommended for production)
  # Set to false to log synchronously (useful for debugging)
  # config.async_logging = true

  # Number of retry attempts for the async logging job on failure
  # config.job_retry_attempts = 3

  # Retention period for execution records (used by cleanup tasks)
  # config.retention_period = 30.days

  # ============================================
  # Anomaly Detection
  # ============================================

  # Executions exceeding these thresholds are logged as warnings
  # config.anomaly_cost_threshold = 5.00        # dollars
  # config.anomaly_duration_threshold = 10_000  # milliseconds

  # ============================================
  # Dashboard Authentication
  # ============================================

  # Option 1: HTTP Basic Auth (simple username/password protection)
  # Both username and password must be set to enable Basic Auth
  # config.basic_auth_username = "admin"
  # config.basic_auth_password = Rails.application.credentials.agents_password

  # Option 2: Custom authentication (advanced)
  # Return true to allow access, false to deny
  # Note: If basic_auth is set, it takes precedence over dashboard_auth
  # config.dashboard_auth = ->(controller) { controller.current_user&.admin? }

  # Parent controller for dashboard (for authentication/layout inheritance)
  # config.dashboard_parent_controller = "ApplicationController"
  # config.dashboard_parent_controller = "AdminController"

  # ============================================
  # Dashboard Display
  # ============================================

  # Number of records per page in dashboard listings
  # config.per_page = 25

  # Number of recent executions shown on the dashboard home
  # config.recent_executions_limit = 10

  # ============================================
  # Reliability Defaults
  # ============================================
  # These defaults apply to all agents unless overridden per-agent

  # Default retry configuration
  # - max: Maximum retry attempts (0 = disabled)
  # - backoff: Strategy (:constant or :exponential)
  # - base: Base delay in seconds
  # - max_delay: Maximum delay between retries
  # - on: Additional error classes to retry on (extends defaults)
  # config.default_retries = {
  #   max: 2,
  #   backoff: :exponential,
  #   base: 0.4,
  #   max_delay: 3.0,
  #   on: []
  # }

  # Default fallback models (tried in order when primary model fails)
  # config.default_fallback_models = ["gpt-4o-mini", "claude-3-haiku"]

  # Default total timeout across all retry/fallback attempts (nil = no limit)
  # config.default_total_timeout = 30

  # ============================================
  # Governance - Budget Tracking
  # ============================================

  # Budget limits for cost governance
  # - global_daily/global_monthly: Limits across all agents
  # - per_agent_daily/per_agent_monthly: Per-agent limits (Hash of agent name => limit)
  # - enforcement: :none (disabled), :soft (warn only), :hard (block requests)
  # config.budgets = {
  #   global_daily: 25.0,
  #   global_monthly: 500.0,
  #   per_agent_daily: {
  #     "ContentGeneratorAgent" => 10.0,
  #     "SummaryAgent" => 5.0
  #   },
  #   per_agent_monthly: {
  #     "ContentGeneratorAgent" => 200.0
  #   },
  #   enforcement: :soft
  # }

  # ============================================
  # Governance - Alerts
  # ============================================

  # Alert notifications for important events
  # - slack_webhook_url: Slack incoming webhook URL
  # - webhook_url: Generic webhook URL (receives JSON POST)
  # - on_events: Events to trigger alerts
  #   - :budget_soft_cap - Soft budget limit reached
  #   - :budget_hard_cap - Hard budget limit exceeded
  #   - :breaker_open - Circuit breaker opened
  #   - :agent_anomaly - Cost/duration anomaly detected
  # - custom: Lambda for custom handling
  # config.alerts = {
  #   slack_webhook_url: ENV["SLACK_AGENTS_WEBHOOK"],
  #   webhook_url: ENV["AGENTS_ALERT_WEBHOOK"],
  #   on_events: [:budget_soft_cap, :budget_hard_cap, :breaker_open],
  #   custom: ->(event, payload) {
  #     Rails.logger.info("[AgentAlert] #{event}: #{payload}")
  #   }
  # }

  # ============================================
  # Governance - Data Handling
  # ============================================

  # Whether to persist prompts in execution records
  # Set to false to reduce storage or for privacy compliance
  # config.persist_prompts = true

  # Whether to persist LLM responses in execution records
  # config.persist_responses = true

  # Redaction configuration for PII and sensitive data
  # - fields: Parameter names to redact (extends defaults: password, token, api_key, secret, etc.)
  # - patterns: Regex patterns to match and redact in string values
  # - placeholder: String to replace redacted values with
  # - max_value_length: Truncate values longer than this (nil = no limit)
  # config.redaction = {
  #   fields: %w[ssn credit_card phone_number email],
  #   patterns: [
  #     /\b\d{3}-\d{2}-\d{4}\b/,           # SSN
  #     /\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b/  # Credit card
  #   ],
  #   placeholder: "[REDACTED]",
  #   max_value_length: 5000
  # }
end
