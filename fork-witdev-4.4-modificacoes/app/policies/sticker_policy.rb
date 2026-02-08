class StickerPolicy < ApplicationPolicy
  def index?
    # Allow all authenticated users to view stickers
    true
  end

  def show?
    true
  end

  def packs?
    true
  end

  def send_sticker?
    # Only agents and administrators can send stickers
    account_user.agent? || account_user.administrator?
  end

  def create?
    # Only administrators can create custom stickers (will be implemented in task 4)
    account_user.administrator?
  end

  def upload?
    # Only administrators can upload custom stickers
    account_user.administrator?
  end

  def update?
    account_user.administrator?
  end

  def destroy?
    account_user.administrator?
  end
end