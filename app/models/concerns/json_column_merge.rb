# frozen_string_literal: true

# One JSON column with several writers, and a read-modify-write that spans a network call: the
# copy in memory is already old by the time it is written back, so whatever landed in the row
# during the call is erased, and whatever was deleted comes back. Not a database race, which is
# why it reproduces with no threads at all.
#
# Every caller here is the same shape: read the row, go to the network, write. This re-reads
# under the row lock and merges only the keys being written. The lock covers the read and the
# write and never the call itself, because a lock held across a network round trip is a worse
# problem than the one it would solve.
#
# That last part is only true while the caller is not already inside a database transaction.
# This opens its own, so a caller that wraps the network call in one would hold the row from
# the first write until its own transaction ends, which is the cost this exists to avoid, and
# nothing here can detect it. Measured on the seven callers as they stand: the group syncer's
# chat lock is Redis, and none of the others is inside a transaction while it talks to the
# network.
#
# Column-agnostic on purpose. The same idea is already written out by hand three times, in three
# different columns: `Avatarable#update_avatar_sync_markers!` on `additional_attributes`, and
# `Channel::Whatsapp#update_reachout_time_lock!` and `#update_new_chat_cap!` on
# `provider_connection`. Naming this after any one column would have made a fourth.
#
# The lock is taken on a freshly loaded row rather than through `with_lock`, which reloads the
# receiver and raises outright when it has unsaved changes. That is not a corner case here: a
# Conversation carries a dirty `display_id` from the moment it is created, on purpose, because
# `load_attributes_created_by_db_triggers` reads the trigger's value without reloading so the
# dispatcher still sees `previous_changes`. So the receiver is left untouched, and a caller that
# needs the merged value afterwards has to read it back.
module JsonColumnMerge
  extend ActiveSupport::Concern

  # `attributes` carries the other columns that belong to the same write. It is not a
  # convenience: taking the lock reloads the row, which drops anything unsaved on this object,
  # so a caller that also sets `name` has to hand it over rather than assign it beforehand.
  #
  # `under` writes inside a nested hash and leaves its siblings alone, which is what the CRM
  # writers need: merging their one key at the top level would replace the whole per-CRM hash.
  #
  # Keys are stringified on the way in. Not for the stored value: assigning the column already
  # normalises it, so `{ 'a' => 1, a: 2 }` reaches the row as `{ 'a' => 2 }` either way. It is
  # the comparison below that needs it. That runs before the assignment, against a hash whose
  # keys are Strings, so a symbol-keyed merge of a value that did not change would never look
  # equal, and every call would write and fire its callbacks for nothing.
  #
  # A row that disappeared during the call is not an error. Every caller is enrichment after a
  # network round trip, and before this existed the write simply matched zero rows and the job
  # ended clean; raising here would turn a deleted contact into a job that retries until it
  # gives up.
  def merge_json_column!(column, merge: {}, remove: [], under: nil, attributes: {})
    self.class.transaction do
      row = self.class.lock.find(id)
      stored = merged_attributes(row[column], merge: merge, remove: remove, under: under)

      params = attributes.to_h.merge(column => stored)
      next false if params.all? { |name, value| row[name] == value }

      row.update!(params)
    end
  rescue ActiveRecord::RecordNotFound
    false
  end

  # The case the merge above cannot cover: the key being written is the key another writer just
  # wrote. Two OAuth refreshes of the same row both write `refresh_token`, both exchanged the same
  # one, and a provider that rotates refresh tokens invalidates the old one, so only one of the two
  # pairs is live. Merging leaves whichever wrote last, which can be the dead one, and then the row
  # holds a token the provider will not honour. Last writer wins is the wrong rule here, and no
  # amount of merging changes that: the loser has to notice.
  #
  # `expect` is read under the same lock as the write, so it is a compare-and-set and not a check
  # followed by a hope: each key's stored value has to still be what the caller based its call on.
  # An empty `expect` is a write with no precondition, which is what `merge_json_column!` already is.
  #
  # Answers what happened, unlike the merge, which answers only whether it wrote. A caller that has
  # to log a rotation it spent and hand back the value that won needs the three cases apart, and a
  # boolean would collapse "someone else got there first" into "there was nothing to write".
  def swap_json_column!(column, expect:, merge: {}, attributes: {})
    self.class.transaction do
      row = self.class.lock.find(id)
      current = row[column] || {}

      next :stale unless expect.deep_stringify_keys.all? { |key, value| current[key] == value }

      params = attributes.to_h.merge(column => merged_attributes(current, merge: merge, remove: [], under: nil))
      next :unchanged if params.all? { |name, value| row[name] == value }

      row.update!(params)
      :written
    end
  rescue ActiveRecord::RecordNotFound
    :gone
  end

  private

  def merged_attributes(current, merge:, remove:, under:)
    stored = (current || {}).deep_dup
    removals = Array(remove).map(&:to_s)
    return stored.except(*removals).merge(merge.deep_stringify_keys) if under.blank?

    key = under.to_s
    # A value that is not a hash is not a namespace, whatever it is: replacing it is the only
    # way to write inside it. But do not invent one for a write that has nothing to put there,
    # or clearing a key out of a namespace that never existed would seed an empty one.
    nested = stored[key].is_a?(Hash) ? stored[key] : {}
    nested = nested.except(*removals).merge(merge.deep_stringify_keys)
    stored[key] = nested unless nested.empty? && !stored[key].is_a?(Hash)
    stored
  end
end
