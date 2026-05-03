class Kanban::AutoAddContactService
  def initialize(contact:)
    @contact = contact
    @account = contact.account
    @consultant = contact.consultant
  end

  def perform
    return if @consultant.blank?

    receive_column = KanbanColumn.auto_receive_for(@account)
    return unless receive_column

    board = @account.kanban_boards.find_or_create_by!(user: @consultant)

    return if KanbanCard.exists?(kanban_board: board, contact: @contact)

    KanbanCard.create!(
      kanban_board: board,
      kanban_column: receive_column,
      contact: @contact,
      created_by: @consultant,
      position: KanbanCard.next_position(receive_column.id, board.id)
    )
  end
end
