let { dirname, parse, resolve } = require('path')
let { existsSync } = require('fs')
let { readFile } = require('fs').promises

async function readPkg(cwd) {
  let filePath = resolve(cwd, 'package.json')
  return JSON.parse(await readFile(filePath, 'utf8'))
}

async function findUp(name, cwd = '') {
  let directory = resolve(cwd)
  let { root } = parse(directory)

  while (true) {
    let foundPath = await resolve(directory, name)

    if (existsSync(foundPath)) {
      return foundPath
    }

    if (directory === root) {
      return undefined
    }

    directory = dirname(directory)
  }
}

module.exports = async cwd => {
  let filePath = await findUp('package.json', cwd)

  if (!filePath) {
    return undefined
  }

  return {
    packageJson: await readPkg(dirname(filePath)),
    path: filePath
  }
}
