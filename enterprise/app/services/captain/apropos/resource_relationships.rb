class Captain::Apropos::ResourceRelationships
  # Reflection discovers links, not authority. Every related result is intersected
  # with the existing target resource scope; scoped and polymorphic associations
  # use Rails' association scope rather than guessing a foreign-key join.
  def self.for(resource)
    model = Captain::Apropos::ResourceFields::MODELS.fetch(resource).constantize
    model.reflect_on_all_associations.filter_map do |reflection|
      if reflection.polymorphic?
        targets = polymorphic_targets(model, reflection)
        next [reflection.name.to_s, [targets, reflection.name.to_s, :polymorphic]] unless targets.empty?

        next
      end

      target = Captain::Apropos::ResourceFields::MODELS.key(reflection.class_name)
      next unless target

      [reflection.name.to_s, relationship(target, reflection)]
    end.to_h
  end

  def self.relationship(target, reflection)
    if reflection.macro == :belongs_to && !reflection.scope && !reflection.options[:through] && reflection.association_primary_key == 'id'
      [target, reflection.foreign_key.to_s, :one]
    else
      [target, reflection.name.to_s, :association]
    end
  end

  def self.polymorphic_targets(model, reflection)
    Captain::Apropos::ResourceFields::MODELS.filter_map do |name, class_name|
      candidate = class_name.constantize
      linked = candidate.reflect_on_all_associations.any? do |inverse|
        inverse.options[:as]&.to_sym == reflection.name && inverse.class_name == model.name
      end
      [candidate.polymorphic_name, name] if linked
    end.to_h
  end
end
