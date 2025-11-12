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
	console.log('==========================================')
	console.log('= Pushed. Create Pull Request on GitHub. =')
	console.log('==========================================')
	console.log()
}