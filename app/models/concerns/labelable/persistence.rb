module Labelable::Persistence
  extend ActiveSupport::Concern

  # This concern overrides five acts-as-taggable-on methods through Labelable:
  #
  #   Conversation / Contact
  #     -> Labelable
  #       -> acts-as-taggable-on: reads and writes labels
  #       -> Persistence: decides whether a loaded list should be written
  #
  # The gem writes a label list on save once it has been read, even if the worker
  # only meant to update another field. Each worker has its own copy of the list:
  #
  #   Message worker                  Automation worker
  #   Reads labels: []
  #                                   Adds "runner" to the database
  #   Saves first-reply time
  #   Gem also writes its old []
  #     -> "runner" disappears
  #
  # No label edit was tracked on the message worker's copy, so this deletion can
  # happen without a removal activity. SLA and priority can remain unchanged.
  #
  # We remember the original list and compare it with the list being saved:
  #
  #   Original [] -> current []          -> skip label and cache writes
  #   Original [] -> current ["runner"]  -> let the gem persist the change
  #
  # The gem still performs the database writes. This comparison also notices
  # label_list.add/remove edits, which mutate the list without calling its setter.
  # It prevents unrelated saves from overwriting labels; it does not coordinate
  # two workers that both intentionally edit labels.
  #
  # Gotcha: this assumes nobody reuses a record instance after one of its saves
  # rolled back. The remembered list follows the database on a rollback, so an
  # instance that edits labels again after a rollback can have that edit skipped.
  # The same applies to a dup, which inherits the source record's remembered list.
  # No current caller does either. Load a fresh record instead of reusing one.
  #
  # TODO: remove this concern once Chatwoot runs Rails 8 and acts-as-taggable-on
  # ships a release with upstream commit cbd83ad, which does this in the gem.
  # The author declined to backport it to 13.x, and gem master needs Rails 8.
  included do
    after_commit :forget_tag_lists_before_transaction
    after_rollback :restore_tag_lists_before_transaction
  end

  def tag_list_cache_on(context)
    super.tap do |list|
      @original_tag_lists ||= {}
      @original_tag_lists[context.to_s] ||= list.dup
    end
  end

  # set_tag_list_on replaces the list without reading it, so load the original first.
  def set_tag_list_on(context, new_list)
    tag_list_cache_on(context)
    super
  end

  # Both the tagging and cache callbacks ask this before writing.
  def tag_list_cache_set_on(context)
    super && tag_list_cache_on(context) != @original_tag_lists.fetch(context.to_s)
  end

  # The saved list becomes the new baseline right away, so a second edit in the same
  # transaction is compared with what was just written. The baseline from before the
  # transaction is kept until it ends. If the transaction rolls back, the database still
  # has the old list, so that baseline comes back and a retry persists the edit again.
  def save_tags
    super.tap do
      next unless @original_tag_lists

      @tag_lists_before_transaction ||= @original_tag_lists.dup
      @original_tag_lists.each_key { |context| @original_tag_lists[context] = tag_list_cache_on(context).dup }
    end
  end

  # Reloading discards the old copy, so discard our remembered list too.
  def reload(*)
    @original_tag_lists = nil
    @tag_lists_before_transaction = nil
    super
  end

  private

  def forget_tag_lists_before_transaction
    @tag_lists_before_transaction = nil
  end

  def restore_tag_lists_before_transaction
    @original_tag_lists = @tag_lists_before_transaction if @tag_lists_before_transaction
    @tag_lists_before_transaction = nil
  end
end
