require 'open3'

# Define a method to fetch the git commit hash
def fetch_git_sha
  sha = nil

  if File.directory?('.git')
    stdout, status = Open3.capture2('git', 'rev-parse', 'HEAD', err: File::NULL)
    sha = stdout if status.success?
  end

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
