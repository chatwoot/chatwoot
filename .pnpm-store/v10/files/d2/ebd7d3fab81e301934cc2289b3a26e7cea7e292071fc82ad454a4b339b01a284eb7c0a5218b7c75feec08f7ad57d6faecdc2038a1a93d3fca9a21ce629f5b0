import fs from 'fs-extra'
import { globbySync } from 'globby'
import { normalizePath } from 'vite'

function toDist(file) {
  return normalizePath(file).replace(/^src\//, 'dist/')
}

globbySync('src/**/*').forEach((file) => {
  if (file.endsWith('.vue') || file.endsWith('.ts') || file.endsWith('tsconfig.json')) return
  fs.copy(file, toDist(file))
})
