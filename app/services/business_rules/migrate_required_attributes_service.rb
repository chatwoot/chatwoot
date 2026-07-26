# frozen_string_literal: true

# One-shot: copy conversation_required_attributes into a business_rules
# require_attributes_on_status (resolved) when no equivalent rule exists.
#
#   bundle exec rails business_rules:migrate_required_attributes
#   bundle exec rails business_rules:migrate_required_attributes DRY_RUN=1
module BusinessRules
  class MigrateRequiredAttributesService
    RULE_ID = 'legacy_require_on_resolve'

    def self.perform!(dry_run: false)
      new(dry_run: dry_run).perform!
    end

    def initialize(dry_run: false)
      @dry_run = dry_run
      @migrated = 0
      @skipped = 0
    end

    def perform!
      Account.find_each do |account|
        process_account(account)
      end
      { migrated: @migrated, skipped: @skipped, dry_run: @dry_run }
    end

    private

    def process_account(account)
      keys = Array(account.settings&.dig('conversation_required_attributes')).map(&:to_s).reject(&:blank?)
      if keys.empty?
        @skipped += 1
        return
      end

      rules = Array(account.settings&.dig('business_rules')).map { |r| r.deep_dup }
      if equivalent_rule?(rules, keys)
        @skipped += 1
        return
      end

      rules = upsert_rule(rules, keys)
      @migrated += 1
      return if @dry_run

      settings = (account.settings || {}).deep_dup
      settings['business_rules'] = rules
      account.update!(settings: settings)
    end

    def equivalent_rule?(rules, keys)
      rules.any? do |rule|
        next false unless rule['type'].to_s == 'require_attributes_on_status'
        next false unless rule.dig('config', 'status').to_s == 'resolved'

        existing = Array(rule.dig('config', 'attribute_keys')).map(&:to_s).reject(&:blank?).sort
        existing == keys.sort && ActiveModel::Type::Boolean.new.cast(rule.fetch('enabled', true))
      end
    end

    def upsert_rule(rules, keys)
      idx = rules.index { |r| r['id'].to_s == RULE_ID }
      rule = {
        'id' => RULE_ID,
        'preset_id' => 'require_on_resolve',
        'type' => 'require_attributes_on_status',
        'enabled' => true,
        'name' => 'Required attributes on resolve',
        'config' => { 'status' => 'resolved', 'attribute_keys' => keys }
      }
      if idx
        rules[idx] = rules[idx].merge(rule)
      else
        rules << rule
      end
      rules
    end
  end
end
