# Release process

1. Bump the version in `lib/ruby_llm/schema/version.rb`
2. Run `bundle install` to update the gemspec
3. Commit the changes with a message like "Bump version to X.Y.Z"
4. Run `bundle exec rake release:prepare` to create a release branch and push it to GitHub
5. Github Actions will run the tests and publish the gem if they pass
6. Delete the release branch: `git branch -d release/<version> && git push origin --delete release/<version>`