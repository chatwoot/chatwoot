import { version } from '../version'
import { readFileSync } from 'fs'
import { resolve as resolvePath } from 'path'

function getPackageJsonVersion(): string {
  const packageJson = JSON.parse(
    readFileSync(
      resolvePath(__dirname, '..', '..', '..', 'package.json')
    ).toString()
  )
  return packageJson.version
}

describe('version', () => {
  it('matches version in package.json', async () => {
    expect(version).toBe(getPackageJsonVersion())
  })
})
