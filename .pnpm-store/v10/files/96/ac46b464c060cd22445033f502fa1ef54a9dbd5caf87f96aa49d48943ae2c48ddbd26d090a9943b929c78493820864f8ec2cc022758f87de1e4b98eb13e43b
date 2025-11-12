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

	console.log(exec('git push'))

	console.log()
	console.log('========================================')
	console.log('=           Pushed. Releasing.         =')
	console.log('========================================')
	console.log()

	console.log(exec('npm version patch'))
	console.log(exec('npm publish'))
	console.log(exec('git push'))

	console.log()
	console.log('========================================')
	console.log('=                Released              =')
	console.log('========================================')
	console.log()
}