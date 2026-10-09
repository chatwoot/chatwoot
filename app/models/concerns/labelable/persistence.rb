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
  included do
    after_commit :apply_saved_tag_lists
    after_rollback :discard_saved_tag_lists
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

  # The saved list becomes the new baseline only once the transaction commits.
  # If it rolls back, the database still has the old list, so keep the old baseline
  # and let a retry on this instance persist the edit again.
  def save_tags
    super.tap do
      @saved_tag_lists = @original_tag_lists&.to_h { |context, _| [context, tag_list_cache_on(context).dup] }
    end
  end

  # Reloading discards the old copy, so discard our remembered list too.
  def reload(*)
    @original_tag_lists = nil
    @saved_tag_lists = nil
    super
  end

  private

  def apply_saved_tag_lists
    @original_tag_lists&.merge!(@saved_tag_lists) if @saved_tag_lists
    @saved_tag_lists = nil
  end

  def discard_saved_tag_lists
    @saved_tag_lists = nil
  end
end
