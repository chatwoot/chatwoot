require 'test_helper'
require 'rails/generators/test_case'
require 'generators/rails/jbuilder_generator'

class JbuilderGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::JbuilderGenerator
  arguments %w(Post title body:text password:digest)
  destination File.expand_path('../tmp', __FILE__)
  setup :prepare_destination

  test 'views are generated' do
    run_generator

    %w(index show).each do |view|
      assert_file "app/views/posts/#{view}.json.jbuilder"
    end
    assert_file "app/views/posts/_post.json.jbuilder"
  end

  test 'index content' do
    run_generator

    assert_file 'app/views/posts/index.json.jbuilder' do |content|
      assert_match %r{json\.array! @posts, partial: "posts/post", as: :post}, content
    end

    assert_file 'app/views/posts/show.json.jbuilder' do |content|
      assert_match %r{json\.partial! "posts/post", post: @post}, content
    end

    assert_file 'app/views/posts/_post.json.jbuilder' do |content|
      assert_match %r{json\.extract! post, :id, :title, :body}, content
      assert_match %r{:created_at, :updated_at}, content
      assert_match %r{json\.url post_url\(post, format: :json\)}, content
    end
  end

  test 'timestamps are not generated in partial with --no-timestamps' do
    run_generator %w(Post title body:text --no-timestamps)

    assert_file 'app/views/posts/_post.json.jbuilder' do |content|
      assert_match %r{json\.extract! post, :id, :title, :body$}, content
      assert_no_match %r{:created_at, :updated_at}, content
    end
  end

  if Rails::VERSION::MAJOR >= 6
    test 'handles virtual attributes' do
      run_generator %w(Message content:rich_text video:attachment photos:attachments)

      assert_file 'app/views/messages/_message.json.jbuilder' do |content|
        assert_match %r{json\.content message\.content\.to_s}, content
        assert_match %r{json\.video url_for\(message\.video\)}, content
        assert_match %r{json\.photos do\n  json\.array!\(message\.photos\) do \|photo\|\n    json\.id photo\.id\n    json\.url url_for\(photo\)\n  end\nend}, content
      end
    end
  end
end
