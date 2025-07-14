import fs from 'fs'
import { download } from 'libphonenumber-metadata-generator'

const url = process.argv[2]
const outputPath = process.argv[3]

download(url).then((contents) => {
	fs.writeFileSync(outputPath, contents)
}).catch((error) => {
	console.error(error)
	process.exit(1)
})