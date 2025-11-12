import exec from './exec.js'

export default function()
{
	var metadata_changed = exec('git ls-files --modified PhoneNumberMetadata.xml')

	if (!metadata_changed)
	{
		console.log()
		console.log('========================================')
		console.log('=   Metadata is up-to-date. Exiting.   =')
		console.log('========================================')
		console.log()

		return
	}

	console.log()
	console.log('========================================')
	console.log('= Metadata has changed, updating files =')
	console.log('========================================')
	console.log()

	console.log(exec('npm run metadata:generate'))

	console.log()
	console.log('========================================')
	console.log('=             Running tests            =')
	console.log('========================================')
	console.log()

	// console.log('* Actually not running tests because if they fail then it won\'t be reported in any way, and if instead tests fail for the Pull Request on github then the repo owner will be notified by Travis CI about that.')
	console.log(exec('npm run build'))
	console.log(exec('npm test'))

	var modified_files = exec('git ls-files --modified').split(/\s/)

	var unexpected_modified_files = modified_files.filter(function(file)
	{
		return file !== 'PhoneNumberMetadata.xml' &&
			!/^metadata\.[a-z]+\.json$/.test(file) &&
			!/^examples\.[a-z]+\.json$/.test(file)
	})

	// Turned off this "modified files" check
	// because on Windows random files constantly got "modified"
	// without actually being modified.
	// (perhaps something related to line endings)
	if (false && unexpected_modified_files.length > 0)
	{
		var error

		error += 'Only `PhoneNumberMetadata.xml`, `metadata.*.json` and `examples.*.json` files should be modified. Unexpected modified files:'
		error += '\n'
		error += '\n'
		error += unexpected_modified_files.join('\n')

		console.log()
		console.log('========================================')
		console.log('=                 Error                =')
		console.log('========================================')
		console.log()
		console.log(error)

		throw new Error(error)
	}

	// Doesn't work
	//
	// // http://stackoverflow.com/questions/33610682/git-list-of-staged-files
	// var staged_files = exec('git diff --name-only --cached').split(/\s/)
	//
	// if (staged_files.length > 0)
	// {
	// 	console.log()
	// 	console.log('========================================')
	// 	console.log('=                 Error                =')
	// 	console.log('========================================')
	// 	console.log()
	// 	console.log('There are some staged files already. Aborting metadata update process.')
	// 	console.log()
	// 	console.log(staged_files.join('\n'))
	//
	// 	process.exit(1)
	// }

	return true
}