module Labelable::Persistence
  # This concern overrides four acts-as-taggable-on methods through Labelable:
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
  def tag_list_cache_on(context)
    super.tap do |list|
      @original_tag_lists ||= {}
      @original_tag_lists[context.to_s] ||= list.dup
    end
  end

  # Both the tagging and cache callbacks ask this before writing.
  def tag_list_cache_set_on(context)
    super && tag_list_cache_on(context) != @original_tag_lists.fetch(context.to_s)
  end

  # After a successful save, the saved list becomes the new comparison baseline.
  def save_tags
    super.tap do
      @original_tag_lists&.each_key do |context|
        @original_tag_lists[context] = tag_list_cache_on(context).dup
      end
    end
  end

  # Reloading discards the old copy, so discard our remembered list too.
  def reload(*)
    @original_tag_lists = nil
    super
  end
end
