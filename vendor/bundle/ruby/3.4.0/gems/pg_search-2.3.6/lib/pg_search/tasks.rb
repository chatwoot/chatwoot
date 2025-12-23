# frozen_string_literal: true

require 'rake'
require 'pg_search'

namespace :pg_search do
  namespace :multisearch do
    desc "Rebuild PgSearch multisearch records for a given model"
    task :rebuild, %i[model schema] => :environment do |_task, args|
      raise ArgumentError, <<~MESSAGE unless args.model

        You must pass a model as an argument.
        Example: rake pg_search:multisearch:rebuild[BlogPost]
      MESSAGE

      model_class = args.model.classify.constantize
      connection = PgSearch::Document.connection
      original_schema_search_path = connection.schema_search_path
      begin
        connection.schema_search_path = args.schema if args.schema
        PgSearch::Multisearch.rebuild(model_class)
      ensure
        connection.schema_search_path = original_schema_search_path
      end
    end
  end
end
