import path from 'pathe'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)

export const APP_PATH = path.join(path.dirname(require.resolve('@histoire/app/package.json')), process.env.HISTOIRE_DEV ? 'src' : 'dist')

export const TEMP_PATH = path.join(process.cwd(), 'node_modules', '.histoire')
