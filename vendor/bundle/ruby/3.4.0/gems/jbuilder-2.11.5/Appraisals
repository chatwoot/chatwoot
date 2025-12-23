appraise "rails-5-0" do
  gem "rails", "~> 5.0.0"
end

appraise "rails-5-1" do
  gem "rails", "~> 5.1.0"
end

appraise "rails-5-2" do
  gem "rails", "~> 5.2.0"
end

if RUBY_VERSION >= "2.5.0"
  appraise "rails-6-0" do
    gem "rails", "~> 6.0.0"
  end

  appraise "rails-6-1" do
    gem "rails", "~> 6.1.0"
  end

  appraise "rails-head" do
    gem "rails", github: "rails/rails", branch: "main"
  end
end
