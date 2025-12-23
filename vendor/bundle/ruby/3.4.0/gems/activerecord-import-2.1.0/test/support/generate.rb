# frozen_string_literal: true

class ActiveSupport::TestCase
  def Build(*args) # rubocop:disable Naming/MethodName
    n = args.shift if args.first.is_a?(Numeric)
    factory = args.shift
    factory_bot_args = args.shift || {}

    if n
      [].tap do |collection|
        n.times.each { collection << FactoryBot.build(factory.to_s.singularize.to_sym, factory_bot_args) }
      end
    else
      FactoryBot.build(factory.to_s.singularize.to_sym, factory_bot_args)
    end
  end

  def Generate(*args) # rubocop:disable Naming/MethodName
    n = args.shift if args.first.is_a?(Numeric)
    factory = args.shift
    factory_bot_args = args.shift || {}

    if n
      [].tap do |collection|
        n.times.each { collection << FactoryBot.create(factory.to_s.singularize.to_sym, factory_bot_args) }
      end
    else
      FactoryBot.create(factory.to_s.singularize.to_sym, factory_bot_args)
    end
  end
end
