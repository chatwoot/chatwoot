require 'test_helper'
require 'rails/generators/test_case'
require 'generators/rails/scaffold_controller_generator'

if Rails::VERSION::MAJOR > 4

  class ScaffoldApiControllerGeneratorTest < Rails::Generators::TestCase
    tests Rails::Generators::ScaffoldControllerGenerator
    arguments %w(Post title body:text images:attachments --api)
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

        assert_instance_method :create, content do |m|
          assert_match %r{@post = Post\.new\(post_params\)}, m
          assert_match %r{@post\.save}, m
          assert_match %r{render :show, status: :created, location: @post}, m
          assert_match %r{render json: @post\.errors, status: :unprocessable_entity}, m
        end

        assert_instance_method :update, content do |m|
          assert_match %r{render :show, status: :ok, location: @post}, m
          assert_match %r{render json: @post.errors, status: :unprocessable_entity}, m
        end

        assert_instance_method :destroy, content do |m|
          assert_match %r{@post\.destroy}, m
        end

        assert_match %r{def post_params}, content
        if Rails::VERSION::MAJOR >= 6
          assert_match %r{params\.require\(:post\)\.permit\(:title, :body, images: \[\]\)}, content
        else
          assert_match %r{params\.require\(:post\)\.permit\(:title, :body, :images\)}, content
        end
      end
    end

    test "don't use require and permit if there are no attributes" do
      run_generator %w(Post --api)

      assert_file 'app/controllers/posts_controller.rb' do |content|
        assert_match %r{def post_params}, content
        assert_match %r{params\.fetch\(:post, \{\}\)}, content
      end
    end


    if Rails::VERSION::MAJOR >= 6
      test 'handles virtual attributes' do
        run_generator ["Message", "content:rich_text", "video:attachment", "photos:attachments"]

        assert_file 'app/controllers/messages_controller.rb' do |content|
          assert_match %r{params\.require\(:message\)\.permit\(:content, :video, photos: \[\]\)}, content
        end
      end
    end
  end
end
