module Api
  module V1
    class EmailInboxesController < Api::BaseController
      def create
        ActiveRecord::Base.transaction do
          channel = email_inboxes.create!(email: permitted_params[:email])
          inbox = inboxes.create!(name: permitted_params[:name], channel: channel)
          render json: inbox
        end
      end

      private

      def inboxes
        current_account.inboxes
      end

      def email_inboxes
        current_account.email_inboxes
      end

      def permitted_params
        params.permit(:name, :email)
      end

    end
  end
end
