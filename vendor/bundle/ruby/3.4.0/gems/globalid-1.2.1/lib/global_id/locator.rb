require 'active_support/core_ext/enumerable' # For Enumerable#index_by

class GlobalID
  module Locator
    class InvalidModelIdError < StandardError; end

    class << self
      # Takes either a GlobalID or a string that can be turned into a GlobalID
      #
      # Options:
      # * <tt>:includes</tt> - A Symbol, Array, Hash or combination of them.
      #   The same structure you would pass into a +includes+ method of Active Record.
      #   If present, locate will load all the relationships specified here.
      #   See https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations.
      # * <tt>:only</tt> - A class, module or Array of classes and/or modules that are
      #   allowed to be located.  Passing one or more classes limits instances of returned
      #   classes to those classes or their subclasses.  Passing one or more modules in limits
      #   instances of returned classes to those including that module.  If no classes or
      #   modules match, +nil+ is returned.
      def locate(gid, options = {})
        gid = GlobalID.parse(gid)

        return unless gid && find_allowed?(gid.model_class, options[:only])

        locator = locator_for(gid)

        if locator.method(:locate).arity == 1
          GlobalID.deprecator.warn "It seems your locator is defining the `locate` method only with one argument. Please make sure your locator is receiving the options argument as well, like `locate(gid, options = {})`."
          locator.locate(gid)
        else
          locator.locate(gid, options.except(:only))
        end
      end

      # Takes an array of GlobalIDs or strings that can be turned into a GlobalIDs.
      # All GlobalIDs must belong to the same app, as they will be located using
      # the same locator using its locate_many method.
      #
      # By default the GlobalIDs will be located using Model.find(array_of_ids), so the
      # models must respond to that finder signature.
      #
      # This approach will efficiently call only one #find (or #where(id: id), when using ignore_missing)
      # per model class, but still interpolate the results to match the order in which the gids were passed.
      #
      # Options:
      # * <tt>:includes</tt> - A Symbol, Array, Hash or combination of them
      #   The same structure you would pass into a includes method of Active Record.
      #   @see https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations
      #   If present, locate_many will load all the relationships specified here.
      #   Note: It only works if all the gids models have that relationships.
      # * <tt>:only</tt> - A class, module or Array of classes and/or modules that are
      #   allowed to be located.  Passing one or more classes limits instances of returned
      #   classes to those classes or their subclasses.  Passing one or more modules in limits
      #   instances of returned classes to those including that module.  If no classes or
      #   modules match, +nil+ is returned.
      # * <tt>:ignore_missing</tt> - By default, locate_many will call #find on the model to locate the
      #   ids extracted from the GIDs. In Active Record (and other data stores following the same pattern),
      #   #find will raise an exception if a named ID can't be found. When you set this option to true,
      #   we will use #where(id: ids) instead, which does not raise on missing records.
      def locate_many(gids, options = {})
        if (allowed_gids = parse_allowed(gids, options[:only])).any?
          locator = locator_for(allowed_gids.first)
          locator.locate_many(allowed_gids, options)
        else
          []
        end
      end

      # Takes either a SignedGlobalID or a string that can be turned into a SignedGlobalID
      #
      # Options:
      # * <tt>:includes</tt> - A Symbol, Array, Hash or combination of them
      #   The same structure you would pass into a includes method of Active Record.
      #   @see https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations
      #   If present, locate_signed will load all the relationships specified here.
      # * <tt>:only</tt> - A class, module or Array of classes and/or modules that are
      #   allowed to be located.  Passing one or more classes limits instances of returned
      #   classes to those classes or their subclasses.  Passing one or more modules in limits
      #   instances of returned classes to those including that module.  If no classes or
      #   modules match, +nil+ is returned.
      def locate_signed(sgid, options = {})
        SignedGlobalID.find sgid, options
      end

      # Takes an array of SignedGlobalIDs or strings that can be turned into a SignedGlobalIDs.
      # The SignedGlobalIDs are located using Model.find(array_of_ids), so the models must respond to
      # that finder signature.
      #
      # This approach will efficiently call only one #find per model class, but still interpolate
      # the results to match the order in which the gids were passed.
      #
      # Options:
      # * <tt>:includes</tt> - A Symbol, Array, Hash or combination of them
      #   The same structure you would pass into a includes method of Active Record.
      #   @see https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations
      #   If present, locate_many_signed will load all the relationships specified here.
      #   Note: It only works if all the gids models have that relationships.
      # * <tt>:only</tt> - A class, module or Array of classes and/or modules that are
      #   allowed to be located.  Passing one or more classes limits instances of returned
      #   classes to those classes or their subclasses.  Passing one or more modules in limits
      #   instances of returned classes to those including that module.  If no classes or
      #   modules match, +nil+ is returned.
      def locate_many_signed(sgids, options = {})
        locate_many sgids.collect { |sgid| SignedGlobalID.parse(sgid, options.slice(:for)) }.compact, options
      end

      # Tie a locator to an app.
      # Useful when different apps collaborate and reference each others' Global IDs.
      #
      # The locator can be either a block or a class.
      #
      # Using a block:
      #
      #   GlobalID::Locator.use :foo do |gid, options|
      #     FooRemote.const_get(gid.model_name).find(gid.model_id)
      #   end
      #
      # Using a class:
      #
      #   GlobalID::Locator.use :bar, BarLocator.new
      #
      #   class BarLocator
      #     def locate(gid, options = {})
      #       @search_client.search name: gid.model_name, id: gid.model_id
      #     end
      #   end
      def use(app, locator = nil, &locator_block)
        raise ArgumentError, 'No locator provided. Pass a block or an object that responds to #locate.' unless locator || block_given?

        URI::GID.validate_app(app)

        @locators[normalize_app(app)] = locator || BlockLocator.new(locator_block)
      end

      private
        def locator_for(gid)
          @locators.fetch(normalize_app(gid.app)) { DEFAULT_LOCATOR }
        end

        def find_allowed?(model_class, only = nil)
          only ? Array(only).any? { |c| model_class <= c } : true
        end

        def parse_allowed(gids, only = nil)
          gids.collect { |gid| GlobalID.parse(gid) }.compact.select { |gid| find_allowed?(gid.model_class, only) }
        end

        def normalize_app(app)
          app.to_s.downcase
        end
    end

    private
      @locators = {}

      class BaseLocator
        def locate(gid, options = {})
          return unless model_id_is_valid?(gid)
          model_class = gid.model_class
          model_class = model_class.includes(options[:includes]) if options[:includes]

          model_class.find gid.model_id
        end

        def locate_many(gids, options = {})
          ids_by_model = Hash.new { |hash, key| hash[key] = [] }

          gids.each do |gid|
            next unless model_id_is_valid?(gid)
            ids_by_model[gid.model_class] << gid.model_id
          end

          records_by_model_name_and_id = {}

          ids_by_model.each do |model, ids|
            records = find_records(model, ids, ignore_missing: options[:ignore_missing], includes: options[:includes])

            records_by_id = records.index_by do |record|
              record.id.is_a?(Array) ? record.id.map(&:to_s) : record.id.to_s
            end

            records_by_model_name_and_id[model.name] = records_by_id
          end

          gids.filter_map { |gid| records_by_model_name_and_id[gid.model_name][gid.model_id] }
        end

        private
          def find_records(model_class, ids, options)
            model_class = model_class.includes(options[:includes]) if options[:includes]

            if options[:ignore_missing]
              model_class.where(primary_key(model_class) => ids)
            else
              model_class.find(ids)
            end
          end

          def model_id_is_valid?(gid)
            Array(gid.model_id).size == Array(primary_key(gid.model_class)).size
          end

          def primary_key(model_class)
            model_class.respond_to?(:primary_key) ? model_class.primary_key : :id
          end
      end

      class UnscopedLocator < BaseLocator
        def locate(gid, options = {})
          unscoped(gid.model_class) { super }
        end

        private
          def find_records(model_class, ids, options)
            unscoped(model_class) { super }
          end

          def unscoped(model_class)
            if model_class.respond_to?(:unscoped)
              model_class.unscoped { yield }
            else
              yield
            end
          end
      end
      DEFAULT_LOCATOR = UnscopedLocator.new

      class BlockLocator
        def initialize(block)
          @locator = block
        end

        def locate(gid, options = {})
          @locator.call(gid, options)
        end

        def locate_many(gids, options = {})
          gids.map { |gid| locate(gid, options) }
        end
      end
  end
end
