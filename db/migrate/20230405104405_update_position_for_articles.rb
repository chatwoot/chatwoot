class UpdatePositionForArticles < ActiveRecord::Migration[6.1]
  def change
    # Get the unique combinations of account_id and category_id
    groups = Article.select(:account_id, :category_id).distinct

    # Iterate through the groups
    groups.each do |group|
      # Get articles belonging to the current group
      articles = Article.where(account_id: group.account_id, category_id: group.category_id)

      # Separate articles with a position set and those without
      articles_with_position = articles.where.not(position: nil).order(:position, :updated_at)
      articles_without_position = articles.where(position: nil).order(:updated_at)

      # Set the position for articles with a position set, in multiples of 10
      # why multiples of 10? because we want to leave room for articles which can be added in between in case we are editing the order from the DB
      position_counter = 0
      articles_with_position.each do |article|
        position_counter += 10
        article.update(position: position_counter)
      end

      # Set the position for articles without a position, starting from where the last position ended
      articles_without_position.each do |article|
        position_counter += 10
        article.update(position: position_counter)
      end
    end
  end
end
