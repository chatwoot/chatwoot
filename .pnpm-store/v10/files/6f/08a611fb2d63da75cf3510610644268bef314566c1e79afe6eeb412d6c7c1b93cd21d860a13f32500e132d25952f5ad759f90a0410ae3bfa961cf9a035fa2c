import exec from './modules/exec.js'

let metadata_branch_exists = false

try
{
	exec('git rev-parse --verify update-metadata')
	metadata_branch_exists = true
}
catch (error)
{
	if (error.message.indexOf('fatal: Needed a single revision') === -1)
	{
		throw error
	}
}

if (metadata_branch_exists)
{
	console.log(exec('git checkout master'))
	console.log(exec('git branch -D update-metadata'))
}

console.log(exec('git pull'))
console.log(exec('git branch update-metadata origin/master'))
console.log(exec('git checkout update-metadata'))