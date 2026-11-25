require 'rails_helper'

# The module lives in config/initializers/article_list_sort.rb and is prepended at boot, so there is
# no class of ours to name here. What is covered is the order the Articles tab of the help center
# receives (#811): the field and direction it asks for, the default it gets when it asks for nothing
# it knows, and the category view, which keeps the manual order the public portal shows.
describe 'ArticleListSort', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:portal) { create(:portal, account: account) }
  let(:category) { create(:category, portal: portal, account: account, locale: 'en', slug: 'billing') }

  def create_article(**attributes)
    create(:article, account: account, portal: portal, category: category, author: admin, **attributes)
  end

  def list(params = {})
    get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles", headers: admin.create_new_auth_token, params: params
    expect(response).to have_http_status(:success)
    response.parsed_body['payload']
  end

  def ids(params = {})
    list(params).pluck('id')
  end

  describe 'the Articles tab' do
    let!(:oldest) { create_article(title: 'banana', views: 5, created_at: 3.days.ago, updated_at: 1.hour.ago) }
    let!(:middle) { create_article(title: 'Apple', views: nil, created_at: 2.days.ago, updated_at: 3.hours.ago) }
    let!(:newest) { create_article(title: 'cherry', views: 40, created_at: 1.day.ago, updated_at: 2.hours.ago) }

    it 'lists the last updated first when no order is asked for, as it did before' do
      expect(ids).to eq([oldest.id, newest.id, middle.id])
    end

    it 'orders by when the article was last updated, in both directions' do
      expect(ids(sort: '-updated_at')).to eq([oldest.id, newest.id, middle.id])
      expect(ids(sort: 'updated_at')).to eq([middle.id, newest.id, oldest.id])
    end

    it 'orders by when the article was created, in both directions' do
      expect(ids(sort: 'created_at')).to eq([oldest.id, middle.id, newest.id])
      expect(ids(sort: '-created_at')).to eq([newest.id, middle.id, oldest.id])
    end

    it 'orders by title without telling upper from lower case' do
      expect(ids(sort: 'title')).to eq([middle.id, oldest.id, newest.id])
      expect(ids(sort: '-title')).to eq([newest.id, oldest.id, middle.id])
    end

    # The card shows an article that was never counted as 0 views, so that is where it sorts.
    it 'orders by views, an article never viewed counting as none' do
      expect(ids(sort: 'views')).to eq([middle.id, oldest.id, newest.id])
      expect(ids(sort: '-views')).to eq([newest.id, oldest.id, middle.id])
    end

    it 'keeps the order while searching' do
      [oldest, middle, newest].each { |article| article.update_columns(content: 'how to pay an invoice') } # rubocop:disable Rails/SkipsModelValidations

      expect(ids(sort: 'title', query: 'invoice')).to eq([middle.id, oldest.id, newest.id])
    end

    it 'turns down an order it does not know instead of guessing one' do
      ['position', 'author_id', '-', '--updated_at', 'title; DROP TABLE articles', 'views desc'].each do |value|
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles", headers: admin.create_new_auth_token, params: { sort: value }

        expect(response).to have_http_status(:unprocessable_entity), "sort=#{value.inspect}"
      end
    end

    it 'turns down an order sent as a list or a hash' do
      ['sort[]=title', 'sort[field]=title'].each do |query|
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles?#{query}", headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity), query
      end
    end

    it 'reads an empty order as no order asked for' do
      expect(ids(sort: '')).to eq([oldest.id, newest.id, middle.id])
    end

    it 'sends when each article was created, which the card shows when ordering by it' do
      created_at = list.to_h { |article| [article['id'], article['created_at']] }

      expect(created_at[middle.id]).to eq(middle.created_at.to_i)
    end
  end

  describe 'pagination' do
    # Every article ties on the field asked for, so the page boundary is decided by the tie-breaker
    # alone: without one, Postgres is free to hand the same article to both pages.
    it 'neither repeats nor skips an article across pages when articles tie' do
      tied_at = 1.day.ago
      articles = Array.new(30) { create_article(views: 7, created_at: tied_at, updated_at: tied_at) }

      %w[-updated_at created_at -views views].each do |sort|
        seen = ids(sort: sort, page: 1) + ids(sort: sort, page: 2)

        expect(seen).to match_array(articles.map(&:id)), "sort=#{sort}"
      end
    end

    # On a table this small Postgres hands back the same physical order to both pages, so the test
    # above passes with or without a tie-breaker; this one pins the tie-breaker itself.
    it 'breaks a tie by id, in the direction asked for' do
      tied_at = 1.day.ago
      articles = Array.new(3) { create_article(views: 7, created_at: tied_at, updated_at: tied_at) }

      expect(ids(sort: 'views')).to eq(articles.map(&:id).sort)
      expect(ids(sort: '-updated_at')).to eq(articles.map(&:id).sort.reverse)
    end
  end

  describe 'a category' do
    it 'keeps the manual order whatever order the Articles tab asked for' do
      second = create_article(title: 'aaa', position: 20, created_at: 1.day.ago)
      first = create_article(title: 'zzz', position: 10, created_at: 2.days.ago)

      %w[title -created_at views].each do |sort|
        expect(ids(sort: sort, category_slug: category.slug)).to eq([first.id, second.id]), "sort=#{sort}"
      end
    end
  end
end
