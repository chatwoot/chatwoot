# CUSTOMIZAÇÃO_MINHAPLATAFORMA: acts-as-taggable-on v12 renomeou Taggable::Cache para Taggable::Caching.
# A migration db/migrate/20231211010807_add_cached_labels_list.rb ainda referencia o nome antigo.
Rails.application.config.after_initialize do
  mod = ActsAsTaggableOn::Taggable
  mod.const_set(:Cache, mod::Caching) if mod.const_defined?(:Caching) && !mod.const_defined?(:Cache, false)
end
