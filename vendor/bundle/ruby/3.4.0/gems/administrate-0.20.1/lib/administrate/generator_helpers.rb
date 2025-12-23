module Administrate
  module GeneratorHelpers
    def call_generator(generator, *args)
      Rails::Generators.invoke(generator, args, generator_options)
    end

    private

    def generator_options
      { behavior: behavior }
    end
  end
end
