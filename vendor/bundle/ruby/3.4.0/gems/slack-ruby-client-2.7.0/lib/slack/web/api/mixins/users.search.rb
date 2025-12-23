# frozen_string_literal: true
if defined?(Picky)
  module Slack
    module Web
      module Api
        module Mixins
          module Users
            Member = Struct.new :id, :name, :first_name, :last_name, :real_name, :email

            #
            # This method searches for users.
            #
            # @option options [user] :user
            #   Free-formed text to search for.
            def users_search(options = {})
              query = options[:user]
              raise ArgumentError, 'Required arguments :user missing' if query.nil?

              index = Picky::Index.new(:users) do
                category :name
                category :first_name
                category :last_name
                category :real_name
                category :email
              end
              members = users_list.members
              members.each_with_index do |member, id|
                user = Member.new(
                  id,
                  member.name,
                  member.profile.first_name,
                  member.profile.last_name,
                  member.profile.real_name,
                  member.profile.email
                )
                index.add(user)
              end
              ids = Picky::Search.new(index).search(query, 5, 0, unique: true).ids
              results = ids.map { |id| members[id] }
              Slack::Messages::Message.new('ok' => true, 'members' => results)
            end
          end
        end
      end
    end
  end
end
