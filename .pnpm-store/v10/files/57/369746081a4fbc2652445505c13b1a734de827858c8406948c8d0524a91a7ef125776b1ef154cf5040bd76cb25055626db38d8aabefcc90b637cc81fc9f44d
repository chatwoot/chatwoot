// In order for this script to work:
//
// * Install `hub` command line tool: `brew install hub`
// * Create a "Personal Access Token" in GitHub account settings (just "repo_public" would be enough)
// * Tell `hub` to use the token for creating GitHub pull requests: `echo "---\ngithub.com:\n- protocol: https\n  user: GITHUB_USERNAME\n  oauth_token: TOKEN" >> ~/.config/hub`

import update_metadata from './modules/update-metadata.js'
import commit from './modules/commit.js'
import exec from './modules/exec.js'

if (update_metadata())
{
	commit()

	console.log()
	console.log('========================================')
	console.log('=           Pushing changes            =')
	console.log('========================================')
	console.log()

	// Delete previous `update-metadata` remote branch
	// (if it already exists)
	if (exec('git ls-remote --heads origin update-metadata'))
	{
		console.log(exec('git push origin update-metadata --delete'))
	}

	// Push the local `update-metadata` branch to GitHub
	console.log(exec('git push origin update-metadata'))

	console.log()
	console.log('========================================')
	console.log('=    Pushed. Creating Pull Request.    =')
	console.log('========================================')
	console.log()

	console.log(exec('hub pull-request -m "Updated metadata" -b catamphetamine/libphonenumber-js:master -h update-metadata'))

	console.log()
	console.log('========================================')
	console.log('=         Pull Request created         =')
	console.log('========================================')
	console.log()

	console.log(exec('git checkout master'))
	console.log(exec('git branch -D update-metadata'))
}