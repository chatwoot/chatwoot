namespace :release do
  desc "Prepare and push the release branch to trigger the automated pipeline"
  task :prepare do
    abort "Git working directory not clean. Commit or stash changes first." unless `git status --porcelain`.strip.empty?
    abort "Not on main branch. Releases must be run from main branch" unless `git rev-parse --abbrev-ref HEAD`.strip == "main"

    require_relative "../ruby_llm/schema/version"
    version = RubyLlm::Schema::VERSION or abort "Could not determine version"

    branch = "release/#{version}"

    if system("git rev-parse --quiet --verify refs/tags/v#{version} > /dev/null 2>&1")
      abort "Tag v#{version} already exists. Bump the version first."
    end

    if system("git show-ref --verify --quiet refs/heads/#{branch}")
      abort "Local branch #{branch} already exists. Remove it or choose a new version."
    end

    sh "git fetch origin"

    if system("git ls-remote --exit-code --heads origin #{branch} > /dev/null 2>&1")
      abort "Release branch #{branch} already exists on origin. Remove it or choose a new version."
    end

    sh "git checkout -b #{branch}"
    sh "git push -u origin #{branch}"

    puts "Release branch #{branch} pushed. GitHub Actions will run tests and publish if they pass."
  ensure
    system "git checkout main"
  end
end
