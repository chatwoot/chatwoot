# The Articles tab of the help center lists every article of the portal in one place, and upstream
# always orders it by the last update (#811). With a few dozen articles, finding one meant knowing
# its title well enough to search for it. The tab now asks for an order: one of the fields below,
# prefixed with `-` for descending, the format the contacts list already uses.
#
# A category keeps the manual order: it is the order the public portal shows, and the one an agent
# edits by dragging, so the tab's choice does not reach it.
#
# Declared here instead of as an autoloaded class, for the reason import_guards.rb gives: a
# reloadable module handed to `prepend` is a new object after every reload. Prepended rather than
# edited in, because the controller is upstream's and every line there is a conflict on every sync.
module ArticleListSort
  ARTICLES = Arel::Table.new(:articles)

  # Title ignores case so the order does not depend on the database collation: under "C", the one
  # some self-hosted Postgres images ship with, "Zebra" would come before "apple". An article never
  # viewed has no count rather than 0, and the card shows it as 0, so that is where it sorts.
  FIELDS = {
    'updated_at' => ARTICLES[:updated_at],
    'created_at' => ARTICLES[:created_at],
    'title' => Arel::Nodes::NamedFunction.new('LOWER', [ARTICLES[:title]]),
    'views' => Arel::Nodes::NamedFunction.new('COALESCE', [ARTICLES[:views], Arel::Nodes.build_quoted(0)])
  }.freeze
  DEFAULT = '-updated_at'.freeze
  PATTERN = /\A(-?)(#{FIELDS.keys.join('|')})\z/

  module Controller
    def index
      return render_could_not_create_error(I18n.t('errors.articles.invalid_sort')) unless article_sort_match

      super
      return if list_params[:category_slug].present?

      # Ties are broken by id, or the page boundary would be the database's to pick and the same
      # article could land on two pages while another lands on none.
      descending, field = article_sort_match.captures.map(&:presence)
      direction = descending ? :desc : :asc
      @articles = @articles.reorder(FIELDS[field].public_send(direction), ARTICLES[:id].public_send(direction))
    end

    private

    # `sort[]=title` arrives as an Array and `sort[field]=title` as a Hash; matching either would
    # raise instead of turning the request down.
    def article_sort_match
      sort = params[:sort].presence || DEFAULT
      @article_sort_match ||= PATTERN.match(sort) if sort.is_a?(String)
    end
  end
end

Rails.application.config.to_prepare do
  Api::V1::Accounts::ArticlesController.prepend(ArticleListSort::Controller)
end
