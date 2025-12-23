
class Assignments
  def test_op_asgn
    foo.bar += User.size
    foo.bar -= User.size
  end

  def nested_assignment
    @email ||= if (email = session["email"]).present?
        User.where(email: email).first
      else
        nil
      end
  end

  def paginate_collection(coll)
    page = (params[:page].present? ? params[:page].to_i : 1)
    per_page = (params[:per_page].present? ? params[:per_page].to_i : 20)
    pagination, self.collection = pagy(
      coll,
      items: per_page,
      page: page
    )
    headers[PAGINATION_TOTAL_HEADER] = pagination.count.to_s
    headers[PAGINATION_TOTAL_PAGES_HEADER] = pagination.pages.to_s
    headers[PAGINATION_PER_PAGE_HEADER] = per_page.to_s
    headers[PAGINATION_PAGE_HEADER] = pagination.page.to_s
    headers[PAGINATION_NEXT_PAGE_HEADER] = pagination.next.to_s
    collection
  end
end
