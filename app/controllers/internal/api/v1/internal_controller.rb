module Internal
  module Api
    module V1
      class InternalController < ApplicationController
        # Override authentication methods to bypass them
        def authenticate_access_token!
          # Do nothing - bypass authentication
        end

        def authenticate_user!
          # Do nothing - bypass authentication
        end

        def validate_bot_access_token!
          # Do nothing - bypass authentication
        end

        def authenticate_by_access_token?
          false # Never authenticate by access token
        end

        def check_authorization(model = nil)
          # Do nothing - bypass authorization
        end

        def create_agent_bot
          account_id = params[:account_id]
          
          unless account_id.present?
            return render json: { error: 'account_id is required' }, status: :bad_request
          end

          account = Account.find_by(id: account_id)
          unless account
            return render json: { error: 'Account not found' }, status: :not_found
          end

          begin
            agent_bot = AgentBot.create!(
              name: params[:name],
              description: params[:description],
              outgoing_url: "http://chatwoot-agent-bot-v2.default.svc.cluster.local:3000/omni-purchase-window-response",
              bot_type: :webhook,
              account: account
            )
            
            render json: {
              status: 'success',
              message: 'Agent bot created successfully',
              agent_bot_id: agent_bot.id,
              agent_bot: {
                id: agent_bot.id,
                name: agent_bot.name,
                description: agent_bot.description,
                outgoing_url: agent_bot.outgoing_url,
                bot_type: agent_bot.bot_type,
                account_id: agent_bot.account_id,
                created_at: agent_bot.created_at
              }
            }, status: :created
          rescue ActiveRecord::RecordInvalid => e
            render json: { 
              error: 'Failed to create agent bot',
              details: e.record.errors.full_messages 
            }, status: :unprocessable_entity
          rescue => e
            render json: { 
              error: 'Internal server error',
              details: e.message 
            }, status: :internal_server_error
          end
        end

        def get_agent_bot_by_inbox
          account_id = params[:account_id]
          inbox_id = params[:inbox_id]
          
          unless account_id.present? && inbox_id.present?
            return render json: { error: 'account_id and inbox_id are required' }, status: :bad_request
          end

          account = Account.find_by(id: account_id)
          unless account
            return render json: { error: 'Account not found' }, status: :not_found
          end

          inbox = account.inboxes.find_by(id: inbox_id)
          unless inbox
            return render json: { error: 'Inbox not found' }, status: :not_found
          end

          agent_bot = inbox.agent_bot
          unless agent_bot
            return render json: { error: 'No agent bot configured for this inbox' }, status: :not_found
          end

          render json: {
            status: 'success',
            agent_bot: {
              id: agent_bot.id,
              name: agent_bot.name,
              description: agent_bot.description,
              outgoing_url: agent_bot.outgoing_url,
              bot_type: agent_bot.bot_type,
              account_id: agent_bot.account_id,
              inbox_id: inbox_id.to_i,
              created_at: agent_bot.created_at,
              updated_at: agent_bot.updated_at
            }
          }, status: :ok
        end

        def update_agent_bot_name
          account_id = params[:account_id]
          agent_bot_id = params[:agent_bot_id]
          new_name = params[:name]
          
          unless account_id.present? && agent_bot_id.present? && new_name.present?
            return render json: { error: 'account_id, agent_bot_id, and name are required' }, status: :bad_request
          end

          account = Account.find_by(id: account_id)
          unless account
            return render json: { error: 'Account not found' }, status: :not_found
          end

          agent_bot = account.agent_bots.find_by(id: agent_bot_id)
          unless agent_bot
            return render json: { error: 'Agent bot not found' }, status: :not_found
          end

          begin
            agent_bot.update!(name: new_name)
            
            render json: {
              status: 'success',
              message: 'Agent bot name updated successfully',
              agent_bot: {
                id: agent_bot.id,
                name: agent_bot.name,
                description: agent_bot.description,
                outgoing_url: agent_bot.outgoing_url,
                bot_type: agent_bot.bot_type,
                account_id: agent_bot.account_id,
                created_at: agent_bot.created_at,
                updated_at: agent_bot.updated_at
              }
            }, status: :ok
          rescue ActiveRecord::RecordInvalid => e
            render json: { 
              error: 'Failed to update agent bot name',
              details: e.record.errors.full_messages 
            }, status: :unprocessable_entity
          rescue => e
            render json: { 
              error: 'Internal server error',
              details: e.message 
            }, status: :internal_server_error
          end
        end

        def delete_agent_bot
          account_id = params[:account_id]
          agent_bot_id = params[:agent_bot_id]
          
          unless account_id.present? && agent_bot_id.present?
            return render json: { error: 'account_id and agent_bot_id are required' }, status: :bad_request
          end

          account = Account.find_by(id: account_id)
          unless account
            return render json: { error: 'Account not found' }, status: :not_found
          end

          agent_bot = account.agent_bots.find_by(id: agent_bot_id)
          unless agent_bot
            return render json: { error: 'Agent bot not found' }, status: :not_found
          end

          begin
            # Store agent bot info before deletion for response
            agent_bot_info = {
              id: agent_bot.id,
              name: agent_bot.name,
              description: agent_bot.description,
              outgoing_url: agent_bot.outgoing_url,
              bot_type: agent_bot.bot_type,
              account_id: agent_bot.account_id,
              created_at: agent_bot.created_at,
              updated_at: agent_bot.updated_at
            }
            
            agent_bot.destroy!
            
            render json: {
              status: 'success',
              message: 'Agent bot deleted successfully',
              deleted_agent_bot: agent_bot_info
            }, status: :ok
          rescue ActiveRecord::RecordNotDestroyed => e
            render json: { 
              error: 'Failed to delete agent bot',
              details: e.record.errors.full_messages 
            }, status: :unprocessable_entity
          rescue => e
            render json: { 
              error: 'Internal server error',
              details: e.message 
            }, status: :internal_server_error
          end
        end

        def send_message_to_conversation
          setup_context
          
          conversation = find_conversation
          return unless conversation

          begin
            # Use the MessageBuilder service directly
            mb = Messages::MessageBuilder.new(nil, conversation, params)
            @message = mb.perform
            
            render json: {
              status: 'success',
              message: {
                id: @message.id,
                content: @message.content,
                message_type: @message.message_type,
                created_at: @message.created_at
              }
            }, status: :created
          rescue StandardError => e
            render json: { 
              error: 'Failed to create message',
              details: e.message 
            }, status: :unprocessable_entity
          end
        end

        def assign_conversation
          setup_context
          
          conversation = find_conversation
          return unless conversation

          begin
            if params.key?(:assignee_id)
              agent = Current.account.users.find_by(id: params[:assignee_id])
              conversation.assignee = agent
              conversation.save!
              
              render json: {
                status: 'success',
                assignee: agent ? {
                  id: agent.id,
                  name: agent.name,
                  email: agent.email
                } : nil
              }, status: :ok
            elsif params.key?(:team_id)
              team = Current.account.teams.find_by(id: params[:team_id])
              conversation.update!(team: team)
              
              render json: {
                status: 'success',
                team: team ? {
                  id: team.id,
                  name: team.name
                } : nil
              }, status: :ok
            else
              render json: { error: 'assignee_id or team_id is required' }, status: :bad_request
            end
          rescue StandardError => e
            render json: { 
              error: 'Failed to assign conversation',
              details: e.message 
            }, status: :unprocessable_entity
          end
        end

        def toggle_conversation_status
          setup_context
          
          conversation = find_conversation
          return unless conversation

          begin
            # Toggle between open and resolved
            new_status = conversation.status == 'open' ? 'resolved' : 'open'
            conversation.update!(status: new_status)
            
            render json: {
              status: 'success',
              conversation: {
                id: conversation.id,
                display_id: conversation.display_id,
                status: conversation.status
              }
            }, status: :ok
          rescue StandardError => e
            render json: { 
              error: 'Failed to toggle conversation status',
              details: e.message 
            }, status: :unprocessable_entity
          end
        end

        def get_conversation_messages
          setup_context
          
          conversation = find_conversation
          return unless conversation

          begin
            # Use the MessageFinder service directly
            message_finder = MessageFinder.new(conversation, params)
            @messages = message_finder.perform
            
            render json: {
              status: 'success',
              messages: @messages.map do |message|
                {
                  id: message.id,
                  content: message.content,
                  message_type: message.message_type,
                  private: message.private,
                  created_at: message.created_at,
                  sender: message.sender_type == 'AgentBot' ? {
                    type: 'AgentBot',
                    id: message.sender_id
                  } : {
                    type: message.sender_type,
                    id: message.sender_id
                  }
                }
              end
            }, status: :ok
          rescue StandardError => e
            render json: { 
              error: 'Failed to get messages',
              details: e.message 
            }, status: :unprocessable_entity
          end
        end

        private

        def setup_context
          # Set up Current.account for the internal API
          account_id = params[:account_id]
          account = Account.find_by(id: account_id)
          
          unless account
            render json: { error: 'Account not found' }, status: :not_found
            return
          end
          
          # Set the current account context
          Current.account = account
          
          # For internal API calls, we can use a system user or nil
          Current.user = nil
        end

        def find_conversation
          conversation_id = params[:conversation_id]
          # Try to find by display_id first (the public-facing ID), then by internal id
          conversation = Current.account.conversations.find_by(display_id: conversation_id)
          
          unless conversation
            render json: { error: 'Conversation not found' }, status: :not_found
            return nil
          end
          
          conversation
        end
      end
    end
  end
end 