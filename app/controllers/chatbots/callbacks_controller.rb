class Chatbots::CallbacksController < ApplicationController
    def update_status
        @chatbot = Chatbot.find_by(id: params[:id])
        if @chatbot
            if params[:result] == 'success'
                @chatbot.update(status: 'Enabled')
            else
                @chatbot.update(status: 'Failed')
            end
        end
    end
end
