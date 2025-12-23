module Administrate
  module Generators
    # This class serves only to work around a strange behaviour in Rails 7
    # with Ruby 3.
    #
    # After running the spec for DashboardGenerator, the fake models that
    # it generates (eg: Foo, Shipment) linger around despite being removed
    # explicitly. This causes RouteGenerator to take them into
    # account and generate routes for them, which its spec doesn't expect,
    # causing a spec failure.
    #
    # To avoid this, the spec for DashboardGenerator defines its fake models
    # as children of TestRecord. Then RoutesGenerator explicitly filters
    # child classes of TestRecord when figuring out what models exist.
    #
    # Discussion at https://github.com/thoughtbot/administrate/pull/2324
    class TestRecord < ApplicationRecord
      self.abstract_class = true
    end
  end
end
