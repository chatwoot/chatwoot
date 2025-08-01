module Api
  module V1
    module Accounts
      module DashassistShopify
        class StoresController < Api::V1::Accounts::BaseController
          before_action :authenticate_user!
          before_action :set_account
          before_action :set_store, only: [:show, :toggle_chat_bot]

          def index
            @store = Dashassist::ShopifyStore.find_by!(account_id: @account.id)
            render json: @store
          end

          def show
            render json: @store
          end

          def show_by_inbox
            @store = Dashassist::ShopifyStore.find_by!(inbox_id: params[:inbox_id], account_id: @account.id)
            render json: @store
          end

          def exists
            shop = params[:shop]
            exists = Dashassist::ShopifyStore.exists?(shop: shop)
            render json: { exists: exists }
          end

          def toggle_chat_bot
            enabled = params[:enabled]
            @store.update!(enabled: enabled)
            render json: @store
          end

          private

          def set_account
            @account = current_user.accounts.find(params[:account_id])
          end

          def set_store
            @store = Dashassist::ShopifyStore.find_by!(id: params[:id], account_id: @account.id)
          end
        end
      end
    end
  end
end 