module FactoryBot
  class Evaluation
    def initialize(evaluator, attribute_assigner, to_create, observer)
      @evaluator = evaluator
      @attribute_assigner = attribute_assigner
      @to_create = to_create
      @observer = observer
    end

    delegate :object, :hash, to: :@attribute_assigner

    def create(result_instance)
      case @to_create.arity
      when 2 then @to_create[result_instance, @evaluator]
      else @to_create[result_instance]
      end
    end

    def notify(name, result_instance)
      @observer.update(name, result_instance)
    end
  end
end
