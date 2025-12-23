# frozen_string_literal: true

require "test_prof/factory_prof"

# A standalone Factory Prof printer which is meant to be always enabled

TestProf::FactoryProf.patch!

started_at = TestProf.now
at_exit do
  TestProf::FactoryProf::Printers::NateHeckler.dump(
    TestProf::FactoryProf.result, start_time: started_at
  )
end

TestProf::FactoryProf.start
