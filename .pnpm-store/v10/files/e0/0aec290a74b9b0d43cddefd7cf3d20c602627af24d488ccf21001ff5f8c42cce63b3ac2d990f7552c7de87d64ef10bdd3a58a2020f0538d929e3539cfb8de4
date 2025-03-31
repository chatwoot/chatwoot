import fs from 'fs'

const COMMENT = '// This file is a workaround for a bug in web browsers\' "native"' + '\n' +
	'// ES6 importing system which is uncapable of importing "*.json" files.' + '\n' +
	'// https://github.com/catamphetamine/libphonenumber-js/issues/239'

const path = process.argv[2]
jsonToJs(path)

function jsonToJs(path) {
	let contents = fs.readFileSync(path, 'utf-8')
	contents = COMMENT + '\n' + 'export default ' + contents
	fs.writeFileSync(path + '.js', contents)
}