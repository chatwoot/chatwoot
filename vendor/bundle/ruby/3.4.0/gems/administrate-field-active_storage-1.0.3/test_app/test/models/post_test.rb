require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "post has cover image" do
    post = posts(:one)

    assert post.cover_image.attached?
  end
end
