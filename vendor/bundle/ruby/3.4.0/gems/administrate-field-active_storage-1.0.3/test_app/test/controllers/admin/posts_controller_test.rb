require 'test_helper'

module Admin
  class PostsControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      post = posts(:one)

      get admin_posts_path

      assert_response :ok
      assert_select "td.cell-data--active-storage > a[href='#{admin_post_path(post)}']"
    end

    test "new" do
      get new_admin_post_path

      assert_response :ok
    end

    test "create with valid parameters increases Post count by 1" do
      file = fixture_file_upload("cover_image.jpg")

      assert_difference "Post.count", 1 do
        post admin_posts_path, params: {
          post: {
            title: "New post title",
            cover_image: file
          }
        }
      end

      assert_response :redirect
    end

    test "create with invalid parameters does not increase Post count" do
      file = fixture_file_upload("cover_image.jpg")

      assert_difference "Post.count", 0 do
        post admin_posts_path, params: {
          post: {
            title: "",
            cover_image: file
          }
        }
      end

      assert_response :unprocessable_entity
    end
  end
end
