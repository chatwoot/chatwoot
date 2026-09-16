# Disable the taggings counter cache on tags.
#
# Each tagging INSERT/DELETE would otherwise issue
# `UPDATE tags SET taggings_count = ... WHERE id = ?`, which serialises
# concurrent label writes on the same tag row and deadlocks under
# parallel multi-label updates (refer INF-68)
#
# Safe because Chatwoot does not read `tags.taggings_count` anywhere;
# label reports compute counts directly via GROUP BY on taggings.
ActsAsTaggableOn.tags_counter = false
