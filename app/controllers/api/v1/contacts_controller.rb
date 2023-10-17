class Api::V1::ContactsController < ApplicationController
  def index
    all_contacts = Contact.all
    render json: all_contacts
  end
end
