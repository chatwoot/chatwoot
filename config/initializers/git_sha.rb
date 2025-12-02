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

# CommMate: Check for CommMate-specific git SHA first
def fetch_commmate_git_sha
  if File.exist?('.commmate_git_sha')
    File.read('.commmate_git_sha').strip
  else
    fetch_git_sha
  end
end

# CommMate git SHA (from CommMate repository)
GIT_HASH = fetch_commmate_git_sha

# Chatwoot base git SHA (for reference)
CHATWOOT_GIT_HASH = File.exist?('.git_sha') ? File.read('.git_sha').strip : GIT_HASH
