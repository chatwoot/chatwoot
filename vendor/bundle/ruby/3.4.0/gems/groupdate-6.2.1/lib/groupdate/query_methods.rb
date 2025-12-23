module Groupdate
  module QueryMethods
    Groupdate::PERIODS.each do |period|
      define_method :"group_by_#{period}" do |field, **options|
        Groupdate::Magic::Relation.generate_relation(self,
          period: period,
          field: field,
          **options
        )
      end
    end

    def group_by_period(period, field, permit: nil, **options)
      Groupdate::Magic.validate_period(period, permit)
      send("group_by_#{period}", field, **options)
    end
  end
end
