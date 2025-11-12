import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { defineConfig } from 'rollup'
import ts from 'rollup-plugin-typescript2'
import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import fs from 'fs-extra'
import { globbySync } from 'globby'
import { execaSync } from 'execa'
import { entries } from './entries.js'

const require = createRequire(import.meta.url)
const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  input: entries,

  plugins: [
    resolve({ preferBuiltins: true }),
    commonjs(),
    ts({
      check: false,
      tsconfigOverride: {
        compilerOptions: {
          rootDir: 'src/client',
        },
      },
    }),
    {
      name: 'define',
      transform(code) {
        return code.replace(/__VUE_OPTIONS_API__/g, 'true')
      },
    },
    {
      name: 'process-build',
      closeBundle() {
        try {
          const pkg = fs.readJsonSync('./package.json')
          const tempDir = path.resolve('./node_modules/.temp/histoire-vendors')
          fs.ensureDirSync(tempDir)
          fs.emptyDirSync(tempDir)
          const targetDtsDir = path.resolve('./dist/client/node_modules')
          fs.ensureDirSync(targetDtsDir)
          fs.emptyDirSync(targetDtsDir)
          const tempPkg = {
            name: 'histoire-vendors-temp',
            version: '0.0.0',
            dependencies: {},
          }
          const pkgExports = {}
          const files = globbySync('./dist/client/*.d.ts', { cwd: __dirname })
          for (const file of files) {
            // Retrieve imports from dts
            {
              let content = fs.readFileSync(file, 'utf-8')
              content = content.replace(/from '(.*)'/g, (match, p1) => {
                const data = fs.readJsonSync(require.resolve(`${p1}/package.json`))
                const versionSelector = data.version
                tempPkg.dependencies[p1] = versionSelector
                return `from './node_modules/${p1}'`
              })
              fs.writeFileSync(file, content, 'utf-8')
            }
            // Create entry files in root
            {
              const filepath = file.replace(/\.d\.ts$/, '')
              const content = `import Default from '${filepath}'

export default Default
export * from '${filepath}'\n`.replace(/\n/g, process.platform === 'win32' ? '\r\n' : '\n')
              fs.writeFileSync(path.basename(file).replace(/^b-/, ''), content, 'utf-8')
            }
            // Exports (package.json)
            const importName = path.basename(file).replace(/\.d\.ts$/, '').replace(/^b-/, '')
            pkgExports[`./${importName}`] = file.replace(/\.d\.ts$/, '.js')
          }
          // Install dependencies in temp module
          {
            const tempPkgFile = path.resolve(tempDir, 'package.json')
            fs.writeJsonSync(tempPkgFile, tempPkg)
            execaSync('npm', ['install', '--prefer-offline --legacy-peer-deps'], { cwd: tempDir })
            const dtsFiles = globbySync(['**/*.d.ts', '**/package.json'], {
              cwd: path.join(tempDir, 'node_modules'),
              dot: true,
            })
            for (const dtsFile of dtsFiles) {
              const absoluteDtsFile = path.resolve(tempDir, 'node_modules', dtsFile)
              fs.copySync(absoluteDtsFile, path.resolve(targetDtsDir, dtsFile))
            }
          }
          // Update exports field in package.json
          pkgExports['./*'] = './*'
          pkg.exports = pkgExports
          fs.writeJsonSync('./package.json', pkg, { spaces: 2 })
        }
        catch (e) {
          console.error(e)
        }
      },
    },
  ],

  output: {
    format: 'es',
    exports: 'auto',
    entryFileNames: '[name].js',
    chunkFileNames: '[name].js',
    assetFileNames: '[name][extname]',
    hoistTransitiveImports: false,
    dir: 'dist/client',
  },

  external: [],

  treeshake: false,
  preserveEntrySignatures: 'strict',
})
