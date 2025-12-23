module Administrate
  class Order
    def initialize(attribute = nil, direction = nil, association_attribute: nil)
      @attribute = attribute
      @direction = sanitize_direction(direction)
      @association_attribute = association_attribute
    end

    def apply(relation)
      return order_by_association(relation) unless
        reflect_association(relation).nil?

      order = relation.arel_table[attribute].public_send(direction)

      return relation.reorder(order) if
        column_exist?(relation, attribute)

      relation
    end

    def ordered_by?(attr)
      attr.to_s == attribute.to_s
    end

    def order_params_for(attr)
      {
        order: attr,
        direction: reversed_direction_param_for(attr)
      }
    end

    attr_reader :direction

    private

    attr_reader :attribute, :association_attribute

    def sanitize_direction(direction)
      %w[asc desc].include?(direction.to_s) ? direction.to_sym : :asc
    end

    def reversed_direction_param_for(attr)
      if ordered_by?(attr)
        opposite_direction
      else
        :asc
      end
    end

    def opposite_direction
      direction == :asc ? :desc : :asc
    end

    def order_by_association(relation)
      case relation_type(relation)
      when :has_many
        order_by_count(relation)
      when :belongs_to
        order_by_belongs_to(relation)
      when :has_one
        order_by_has_one(relation)
      else
        relation
      end
    end

    def order_by_count(relation)
      klass = reflect_association(relation).klass
      query = klass.arel_table[klass.primary_key].count.public_send(direction)
      relation.
        left_joins(attribute.to_sym).
        group(:id).
        reorder(query)
    end

    def order_by_belongs_to(relation)
      if ordering_by_association_column?(relation)
        order_by_attribute(relation)
      else
        order_by_id(relation)
      end
    end

    def order_by_has_one(relation)
      if ordering_by_association_column?(relation)
        order_by_attribute(relation)
      else
        order_by_association_id(relation)
      end
    end

    def order_by_attribute(relation)
      relation.joins(
        attribute.to_sym,
      ).reorder(order_by_attribute_query)
    end

    def order_by_id(relation)
      relation.reorder(order_by_id_query(relation))
    end

    def order_by_association_id(relation)
      relation.reorder(order_by_association_id_query)
    end

    def ordering_by_association_column?(relation)
      association_attribute &&
        column_exist?(
          reflect_association(relation).klass, association_attribute.to_sym
        )
    end

    def column_exist?(table, column_name)
      table.columns_hash.key?(column_name.to_s)
    end

    def order_by_id_query(relation)
      relation.arel_table[foreign_key(relation)].public_send(direction)
    end

    def order_by_association_id_query
      Arel::Table.new(association_table_name)[:id].public_send(direction)
    end

    def order_by_attribute_query
      table = Arel::Table.new(association_table_name)
      table[association_attribute].public_send(direction)
    end

    def relation_type(relation)
      reflect_association(relation).macro
    end

    def reflect_association(relation)
      relation.klass.reflect_on_association(attribute.to_s)
    end

    def foreign_key(relation)
      reflect_association(relation).foreign_key
    end

    def association_table_name
      attribute.tableize
    end
  end
end
