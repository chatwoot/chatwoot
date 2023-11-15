# This migration adds a trigram index to the tags table on the name column.
# This is used to speed up the search for tags by name, this is a heavy
# sub query when genereating reports where labels are involved.
#
# Trigram indexes are used to speed up LIKE queries, they are not used for
# equality queries. This is because the index is not a btree index, it is a
# GIN index. This means that the index is not ordered, and so cannot be used
# for equality queries.
#
# Read more: https://www.postgresql.org/docs/current/pgtrgm.html

class AddTrgmIndexToTagName < ActiveRecord::Migration[6.1]
  # disabling ddl transaction is required for concurrent index creation
  # https://thoughtbot.com/blog/how-to-create-postgres-indexes-concurrently-in
  disable_ddl_transaction!

  def change
    add_index :tags, 'LOWER(name) gin_trgm_ops', using: :gin, name: 'tags_name_trgm_idx', algorithm: :concurrently
    # resolves to CREATE INDEX tags_name_trgm_idx ON public.tags USING gin (lower((name)::text) gin_trgm_ops);
  end
end
