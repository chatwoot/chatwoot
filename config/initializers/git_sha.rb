# Define a method to fetch the git commit hash
def fetch_git_sha
  sha = `git rev-parse HEAD` if File.directory?('.git')
  if sha.present?
    sha.strip
  elsif File.exist?('.git_sha')
    File.read('.git_sha').strip
  # This is for Heroku. Ensure heroku labs:enable runtime-dyno-metadata is turned on.
  elsif ENV.fetch('HEROKU_SLUG_COMMIT', nil).present?
    ENV.fetch('HEROKU_SLUG_COMMIT', nil)
  else
    'unknown'
  end
end

GIT_HASH = fetch_git_sha
