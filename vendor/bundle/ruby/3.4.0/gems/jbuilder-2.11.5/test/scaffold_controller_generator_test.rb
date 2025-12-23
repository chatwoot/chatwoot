require 'test_helper'
require 'rails/generators/test_case'
require 'generators/rails/scaffold_controller_generator'

class ScaffoldControllerGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::ScaffoldControllerGenerator
  arguments %w(Post title body:text images:attachments)
  destination File.expand_path('../tmp', __FILE__)
  setup :prepare_destination

  test 'controller content' do
    run_generator

    assert_file 'app/controllers/posts_controller.rb' do |content|
      assert_instance_method :index, content do |m|
        assert_match %r{@posts = Post\.all}, m
      end

      assert_instance_method :show, content do |m|
        assert m.blank?
      end

      assert_instance_method :new, content do |m|
        assert_match %r{@post = Post\.new}, m
      end

      assert_instance_method :edit, content do |m|
        assert m.blank?
      end

      assert_instance_method :create, content do |m|
        assert_match %r{@post = Post\.new\(post_params\)}, m
        assert_match %r{@post\.save}, m
        assert_match %r{format\.html \{ redirect_to post_url\(@post\), notice: "Post was successfully created\." \}}, m
        assert_match %r{format\.json \{ render :show, status: :created, location: @post \}}, m
        assert_match %r{format\.html \{ render :new, status: :unprocessable_entity \}}, m
        assert_match %r{format\.json \{ render json: @post\.errors, status: :unprocessable_entity \}}, m
      end

      assert_instance_method :update, content do |m|
        assert_match %r{format\.html \{ redirect_to post_url\(@post\), notice: "Post was successfully updated\." \}}, m
        assert_match %r{format\.json \{ render :show, status: :ok, location: @post \}}, m
        assert_match %r{format\.html \{ render :edit, status: :unprocessable_entity \}}, m
        assert_match %r{format\.json \{ render json: @post.errors, status: :unprocessable_entity \}}, m
      end

      assert_instance_method :destroy, content do |m|
        assert_match %r{@post\.destroy}, m
        assert_match %r{format\.html \{ redirect_to posts_url, notice: "Post was successfully destroyed\." \}}, m
        assert_match %r{format\.json \{ head :no_content \}}, m
      end

      assert_match %r{def post_params}, content
      if Rails::VERSION::MAJOR >= 6
        assert_match %r{params\.require\(:post\)\.permit\(:title, :body, images: \[\]\)}, content
      else
        assert_match %r{params\.require\(:post\)\.permit\(:title, :body, :images\)}, content
      end
    end
  end

  if Rails::VERSION::MAJOR >= 6
    test 'controller with namespace' do
      run_generator %w(Admin::Post --model-name=Post)
      assert_file 'app/controllers/admin/posts_controller.rb' do |content|
        assert_instance_method :create, content do |m|
          assert_match %r{format\.html \{ redirect_to admin_post_url\(@post\), notice: "Post was successfully created\." \}}, m
        end

        assert_instance_method :update, content do |m|
          assert_match %r{format\.html \{ redirect_to admin_post_url\(@post\), notice: "Post was successfully updated\." \}}, m
        end

        assert_instance_method :destroy, content do |m|
          assert_match %r{format\.html \{ redirect_to admin_posts_url, notice: "Post was successfully destroyed\." \}}, m
        end
      end
    end
  end

  test "don't use require and permit if there are no attributes" do
    run_generator %w(Post)

    assert_file 'app/controllers/posts_controller.rb' do |content|
      assert_match %r{def post_params}, content
      assert_match %r{params\.fetch\(:post, \{\}\)}, content
    end
  end

  if Rails::VERSION::MAJOR >= 6
    test 'handles virtual attributes' do
      run_generator %w(Message content:rich_text video:attachment photos:attachments)

      assert_file 'app/controllers/messages_controller.rb' do |content|
        assert_match %r{params\.require\(:message\)\.permit\(:content, :video, photos: \[\]\)}, content
      end
    end
  end
end
