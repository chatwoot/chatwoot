class Api::V1::Accounts::Kanban::CardsController < Api::V1::Accounts::BaseController
  before_action :find_board
  before_action :find_column, only: [:index, :create]
  before_action :find_card, only: [:update, :move, :destroy]

  def index
    @cards = @column.cards.includes(:contact, :created_by)
    render 'api/v1/accounts/kanban/cards/index'
  end

  def create
    contact = find_or_create_contact
    @card = @board.cards.build(
      kanban_column: @column,
      contact: contact,
      created_by: current_user,
      position: KanbanCard.next_position(@column.id),
      **card_params
    )
    authorize @card
    @card.save!
    render 'api/v1/accounts/kanban/cards/show', status: :created
  end

  def update
    authorize @card
    @card.update!(card_params)
    render 'api/v1/accounts/kanban/cards/show'
  end

  def move
    authorize @card
    target_column = @board.columns.find(params[:column_id])
    before_pos = params[:before_position]&.to_f
    after_pos = params[:after_position]&.to_f

    new_position = calculate_position(before_pos, after_pos, target_column)

    from_column = @card.kanban_column

    ActiveRecord::Base.transaction do
      @card.update!(kanban_column: target_column, position: new_position)
      KanbanCardActivity.create!(
        kanban_card: @card,
        from_column: from_column,
        to_column: target_column,
        user: current_user
      )
    end

    render 'api/v1/accounts/kanban/cards/show'
  end

  def destroy
    authorize @card
    @card.destroy!
    head :ok
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find_by!(user: current_user)
  end

  def find_column
    @column = @board.columns.find(params[:column_id])
  end

  def find_card
    @card = @board.cards.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:potential_value, :notes)
  end

  def find_or_create_contact
    phone = normalize_phone(params.dig(:card, :phone_number))
    email = params.dig(:card, :email)

    contact = Current.account.contacts.find_by(phone_number: phone) if phone.present?
    contact ||= Current.account.contacts.find_by(email: email) if email.present?

    return contact if contact

    Current.account.contacts.create!(
      name: params.dig(:card, :contact_name).presence || phone || email,
      phone_number: phone,
      email: email
    )
  end

  def normalize_phone(phone)
    return if phone.blank?

    cleaned = phone.gsub(/\D/, '')
    return "+#{cleaned}" if cleaned.start_with?('55') && cleaned.length >= 12

    "+55#{cleaned}"
  end

  def calculate_position(before_pos, after_pos, column)
    if before_pos && after_pos
      (before_pos + after_pos) / 2.0
    elsif before_pos
      before_pos + 1.0
    elsif after_pos
      after_pos / 2.0
    else
      KanbanCard.next_position(column.id)
    end
  end
end
