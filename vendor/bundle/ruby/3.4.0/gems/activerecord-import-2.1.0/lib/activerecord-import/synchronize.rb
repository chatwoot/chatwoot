# frozen_string_literal: true

module ActiveRecord # :nodoc:
  class Base # :nodoc:
    # Synchronizes the passed in ActiveRecord instances with data
    # from the database. This is like calling reload on an individual
    # ActiveRecord instance but it is intended for use on multiple instances.
    #
    # This uses one query for all instance updates and then updates existing
    # instances rather sending one query for each instance
    #
    # == Examples
    # # Synchronizing existing models by matching on the primary key field
    # posts = Post.where(author: "Zach").first
    # <.. out of system changes occur to change author name from Zach to Zachary..>
    # Post.synchronize posts
    # posts.first.author # => "Zachary" instead of Zach
    #
    # # Synchronizing using custom key fields
    # posts = Post.where(author: "Zach").first
    # <.. out of system changes occur to change the address of author 'Zach' to 1245 Foo Ln ..>
    # Post.synchronize posts, [:name] # queries on the :name column and not the :id column
    # posts.first.address # => "1245 Foo Ln" instead of whatever it was
    #
    def self.synchronize(instances, keys = [primary_key])
      return if instances.empty?

      conditions = {}

      key_values = keys.map { |key| instances.map(&key.to_sym) }
      keys.zip(key_values).each { |key, values| conditions[key] = values }
      order = keys.map { |key| "#{key} ASC" }.join(",")

      klass = instances.first.class

      fresh_instances = klass.unscoped.where(conditions).order(order)
      instances.each do |instance|
        matched_instance = fresh_instances.detect do |fresh_instance|
          keys.all? { |key| fresh_instance.send(key) == instance.send(key) }
        end

        next unless matched_instance

        instance.instance_variable_set :@association_cache, {}
        instance.send :clear_aggregation_cache if instance.respond_to?(:clear_aggregation_cache, true)
        instance.instance_variable_set :@attributes, matched_instance.instance_variable_get(:@attributes)

        if instance.respond_to?(:clear_changes_information)
          instance.clear_changes_information                      # Rails 4.2 and higher
        else
          instance.instance_variable_set :@attributes_cache, {}   # Rails 4.0, 4.1
          instance.changed_attributes.clear                       # Rails 3.2
          instance.previous_changes.clear
        end

        # Since the instance now accurately reflects the record in
        # the database, ensure that instance.persisted? is true.
        instance.instance_variable_set '@new_record', false
        instance.instance_variable_set '@destroyed', false
      end
    end

    # See ActiveRecord::ConnectionAdapters::AbstractAdapter.synchronize
    def synchronize(instances, key = [ActiveRecord::Base.primary_key])
      self.class.synchronize(instances, key)
    end
  end
end
