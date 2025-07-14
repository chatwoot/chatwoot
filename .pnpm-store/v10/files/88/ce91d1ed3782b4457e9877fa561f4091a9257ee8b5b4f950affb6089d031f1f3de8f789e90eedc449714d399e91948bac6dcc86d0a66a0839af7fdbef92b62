import metadata from '../metadata.min.json' assert { type: 'json' }
import fs from 'fs'

const countryCodes = Object.keys(metadata.countries)

fs.writeFileSync(
	'./types.d.ts',
	fs.readFileSync('./types.d.ts', 'utf-8').replace(
		/export type CountryCode = .*;/,
		`export type CountryCode = ${countryCodes.map(_ => `'${_}'`).join(' | ')};`
	),
	'utf-8'
)