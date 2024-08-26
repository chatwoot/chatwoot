class ConfirmAdmin < ActiveRecord::Migration[7.0]
  def change
    user = User.find_by(id: 3)

    if user
      user.confirm
      puts 'Successfully confirmed email'
    end
  end
end
