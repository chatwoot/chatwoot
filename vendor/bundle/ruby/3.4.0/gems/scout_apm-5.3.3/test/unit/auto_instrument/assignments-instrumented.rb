
class Assignments
  def test_op_asgn
    foo.bar += ::ScoutApm::AutoInstrument("User.size",["ROOT/test/unit/auto_instrument/assignments.rb:4:in `test_op_asgn'"]){User.size}
    foo.bar -= ::ScoutApm::AutoInstrument("User.size",["ROOT/test/unit/auto_instrument/assignments.rb:5:in `test_op_asgn'"]){User.size}
  end

  def nested_assignment
    @email ||= if (email = ::ScoutApm::AutoInstrument("session[\"email\"]",["ROOT/test/unit/auto_instrument/assignments.rb:9:in `nested_assignment'"]){session["email"]}).present?
        ::ScoutApm::AutoInstrument("User.where(email: email).first",["ROOT/test/unit/auto_instrument/assignments.rb:10:in `nested_assignment'"]){User.where(email: email).first}
      else
        nil
      end
  end

  def paginate_collection(coll)
    page = (::ScoutApm::AutoInstrument("params[:page].present?",["ROOT/test/unit/auto_instrument/assignments.rb:17:in `paginate_collection'"]){params[:page].present?} ? ::ScoutApm::AutoInstrument("params[:page].to_i",["ROOT/test/unit/auto_instrument/assignments.rb:17:in `paginate_collection'"]){params[:page].to_i} : 1)
    per_page = (::ScoutApm::AutoInstrument("params[:per_page].present?",["ROOT/test/unit/auto_instrument/assignments.rb:18:in `paginate_collection'"]){params[:per_page].present?} ? ::ScoutApm::AutoInstrument("params[:per_page].to_i",["ROOT/test/unit/auto_instrument/assignments.rb:18:in `paginate_collection'"]){params[:per_page].to_i} : 20)
    pagination, self.collection = ::ScoutApm::AutoInstrument("pagy(...",["ROOT/test/unit/auto_instrument/assignments.rb:19:in `paginate_collection'"]){pagy(
      coll,
      items: per_page,
      page: page
    )}
    ::ScoutApm::AutoInstrument("headers[PAGINATION_TOTAL_HEADER] = pagination.count.to_s",["ROOT/test/unit/auto_instrument/assignments.rb:24:in `paginate_collection'"]){headers[PAGINATION_TOTAL_HEADER] = pagination.count.to_s}
    ::ScoutApm::AutoInstrument("headers[PAGINATION_TOTAL_PAGES_HEADER] = pagination.pages.to_s",["ROOT/test/unit/auto_instrument/assignments.rb:25:in `paginate_collection'"]){headers[PAGINATION_TOTAL_PAGES_HEADER] = pagination.pages.to_s}
    ::ScoutApm::AutoInstrument("headers[PAGINATION_PER_PAGE_HEADER] = per_page.to_s",["ROOT/test/unit/auto_instrument/assignments.rb:26:in `paginate_collection'"]){headers[PAGINATION_PER_PAGE_HEADER] = per_page.to_s}
    ::ScoutApm::AutoInstrument("headers[PAGINATION_PAGE_HEADER] = pagination.page.to_s",["ROOT/test/unit/auto_instrument/assignments.rb:27:in `paginate_collection'"]){headers[PAGINATION_PAGE_HEADER] = pagination.page.to_s}
    ::ScoutApm::AutoInstrument("headers[PAGINATION_NEXT_PAGE_HEADER] = pagination.next.to_s",["ROOT/test/unit/auto_instrument/assignments.rb:28:in `paginate_collection'"]){headers[PAGINATION_NEXT_PAGE_HEADER] = pagination.next.to_s}
    ::ScoutApm::AutoInstrument("collection",["ROOT/test/unit/auto_instrument/assignments.rb:29:in `paginate_collection'"]){collection}
  end
end
