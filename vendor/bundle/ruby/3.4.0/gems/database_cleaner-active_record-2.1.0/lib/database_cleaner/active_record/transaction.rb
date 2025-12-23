require 'database_cleaner/active_record/base'

module DatabaseCleaner
  module ActiveRecord
    class Transaction < Base
      def start
        # Hack to make sure that the connection is properly set up before cleaning
        connection_class.connection.transaction {}

        connection_class.connection.begin_transaction joinable: false
      end


      def clean
        connection_class.connection_pool.connections.each do |connection|
          next unless connection.open_transactions > 0
          connection.rollback_transaction
        end
      end
    end
  end
end
