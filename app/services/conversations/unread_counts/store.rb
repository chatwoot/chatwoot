module Conversations::UnreadCounts
  READY_TTL = 24.hours.to_i
  SET_TTL = 25.hours.to_i
end

class Conversations::UnreadCounts::Store
  extend ::Conversations::UnreadCounts::StoreKeys

  class << self
    def base_ready?(account_id)
      Redis::Alfred.exists?(base_ready_key(account_id))
    end

    def assignment_ready?(account_id)
      Redis::Alfred.exists?(assignment_ready_key(account_id))
    end

    def mark_base_ready!(account_id)
      Redis::Alfred.set(base_ready_key(account_id), Time.current.to_i, ex: Conversations::UnreadCounts::READY_TTL)
    end

    def mark_assignment_ready!(account_id)
      Redis::Alfred.set(assignment_ready_key(account_id), Time.current.to_i, ex: Conversations::UnreadCounts::READY_TTL)
    end

    def clear_account!(account_id)
      delete_matching("#{account_prefix(account_id)}::*")
    end

    def clear_assignment!(account_id)
      assignment_key_patterns(account_id).each { |pattern| delete_matching(pattern) }
    end

    def add_base_membership(account_id:, inbox_id:, label_ids:, conversation_id:, team_id: nil)
      add_to_sets(base_keys(account_id, inbox_id, label_ids, team_id), conversation_id)
    end

    def remove_base_membership(account_id:, inbox_ids:, label_ids:, conversation_id:, team_ids: [])
      keys = Array(inbox_ids).flat_map { |inbox_id| removable_base_keys(account_id, inbox_id, label_ids, team_ids) }
      remove_from_sets(keys, conversation_id)
    end

    def add_assignment_membership(account_id:, conversation_id:, **membership)
      add_to_sets(
        assignment_keys(account_id, membership[:inbox_id], membership[:label_ids], membership[:assignee_id], membership[:team_id]),
        conversation_id
      )
    end

    def remove_assignment_membership(account_id:, conversation_id:, **membership)
      keys = Array(membership[:inbox_ids]).flat_map do |inbox_id|
        Array(membership[:assignee_ids]).flat_map do |assignee_id|
          removable_assignment_keys(account_id, inbox_id, membership[:label_ids], assignee_id, membership[:team_ids])
        end
      end
      remove_from_sets(keys, conversation_id)
    end

    def add_memberships(account_id:, memberships:, assignment: false)
      return if memberships.blank?

      Redis::Alfred.pipelined do |pipeline|
        memberships.each do |membership|
          keys = if assignment
                   assignment_keys(account_id, membership[:inbox_id], membership[:label_ids], membership[:assignee_id], membership[:team_id])
                 else
                   base_keys(account_id, membership[:inbox_id], membership[:label_ids], membership[:team_id])
                 end

          keys.each do |key|
            pipeline.sadd(key, membership[:conversation_id])
            pipeline.expire(key, Conversations::UnreadCounts::SET_TTL)
          end
        end
      end
    end

    def counts_for_keys(keys)
      keys = keys.compact_blank
      return {} if keys.blank?

      counts = Redis::Alfred.pipelined do |pipeline|
        keys.each { |key| pipeline.scard(key) }
      end
      keys.zip(counts).to_h
    end

    def memberships_for_keys(keys, conversation_id)
      keys = keys.compact_blank
      return {} if keys.blank?

      memberships = Redis::Alfred.pipelined do |pipeline|
        keys.each { |key| pipeline.sismember(key, conversation_id) }
      end
      keys.zip(memberships.map { |membership| membership == true || membership == 1 }).to_h
    end

    private

    def base_ready_key(account_id)
      format(Redis::Alfred::UNREAD_CONVERSATIONS_BASE_READY, account_id: account_id)
    end

    def assignment_ready_key(account_id)
      format(Redis::Alfred::UNREAD_CONVERSATIONS_ASSIGNMENT_READY, account_id: account_id)
    end

    def account_prefix(account_id)
      format(Redis::Alfred::UNREAD_CONVERSATIONS_ACCOUNT_PREFIX, account_id: account_id)
    end

    def base_keys(account_id, inbox_id, label_ids, team_id = nil)
      keys = [inbox_key(account_id, inbox_id)] + Array(label_ids).map { |label_id| label_inbox_key(account_id, label_id, inbox_id) }
      keys << team_inbox_key(account_id, team_id, inbox_id) if team_id.present?
      keys
    end

    def removable_base_keys(account_id, inbox_id, label_ids, team_ids)
      keys = base_keys(account_id, inbox_id, label_ids)
      keys.concat(Array(team_ids).compact_blank.map { |team_id| team_inbox_key(account_id, team_id, inbox_id) })
    end

    def assignment_keys(account_id, inbox_id, label_ids, assignee_id, team_id = nil)
      keys = assignment_keys_without_team(account_id, inbox_id, label_ids, assignee_id)
      keys << team_assignment_key(account_id, team_id, inbox_id, assignee_id) if team_id.present?
      keys
    end

    def removable_assignment_keys(account_id, inbox_id, label_ids, assignee_id, team_ids)
      keys = assignment_keys_without_team(account_id, inbox_id, label_ids, assignee_id)
      keys.concat(Array(team_ids).compact_blank.map { |team_id| team_assignment_key(account_id, team_id, inbox_id, assignee_id) })
    end

    def assignment_keys_without_team(account_id, inbox_id, label_ids, assignee_id)
      return assignee_keys(account_id, inbox_id, label_ids, assignee_id) if assignee_id.present?

      unassigned_keys(account_id, inbox_id, label_ids)
    end

    def assignee_keys(account_id, inbox_id, label_ids, assignee_id)
      [inbox_assignee_key(account_id, inbox_id, assignee_id)] +
        Array(label_ids).map { |label_id| label_inbox_assignee_key(account_id, label_id, inbox_id, assignee_id) }
    end

    def unassigned_keys(account_id, inbox_id, label_ids)
      [inbox_unassigned_key(account_id, inbox_id)] +
        Array(label_ids).map { |label_id| label_inbox_unassigned_key(account_id, label_id, inbox_id) }
    end

    def team_assignment_key(account_id, team_id, inbox_id, assignee_id)
      return team_inbox_assignee_key(account_id, team_id, inbox_id, assignee_id) if assignee_id.present?

      team_inbox_unassigned_key(account_id, team_id, inbox_id)
    end

    def add_to_sets(keys, conversation_id)
      write_to_sets(keys) { |pipeline, key| pipeline.sadd(key, conversation_id) }
    end

    def remove_from_sets(keys, conversation_id)
      write_to_sets(keys) { |pipeline, key| pipeline.srem(key, conversation_id) }
    end

    def write_to_sets(keys)
      keys = keys.compact_blank
      return if keys.blank?

      Redis::Alfred.pipelined do |pipeline|
        keys.each do |key|
          yield(pipeline, key)
          pipeline.expire(key, Conversations::UnreadCounts::SET_TTL)
        end
      end
    end

    def delete_matching(pattern)
      Redis::Alfred.scan_each(match: pattern, count: 1000) do |key|
        Redis::Alfred.delete(key)
      end
    end

    def assignment_key_patterns(account_id)
      prefix = account_prefix(account_id)
      [
        assignment_ready_key(account_id),
        "#{prefix}::INBOX::*::UNASSIGNED",
        "#{prefix}::INBOX::*::ASSIGNEE::*",
        "#{prefix}::LABEL::*::INBOX::*::UNASSIGNED",
        "#{prefix}::LABEL::*::INBOX::*::ASSIGNEE::*",
        "#{prefix}::TEAM::*::INBOX::*::UNASSIGNED",
        "#{prefix}::TEAM::*::INBOX::*::ASSIGNEE::*"
      ]
    end
  end
end
