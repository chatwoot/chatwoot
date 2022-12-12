#!/usr/bin/env node

const fs = require('fs');
const prefersColorScheme = require('./postcss');

if (process.argv.length < 3) {
	console.log([
		'Prefers Color Scheme\n',
		'  Transforms CSS with @media (prefers-color-scheme) {}\n',
		'Usage:\n',
		'  css-prefers-color-scheme source.css transformed.css',
		'  css-prefers-color-scheme --in=source.css --out=transformed.css --opts={}',
		'  echo "@media (prefers-color-scheme: dark) {}" | css-prefers-color-scheme\n'
	].join('\n'));
	process.exit(0);
}

// get process and plugin options from the command line
const fileRegExp = /^[\w\/.]+$/;
const argRegExp = /^--(\w+)=("|')?(.+)\2$/;
const relaxedJsonRegExp = /(['"])?([a-z0-9A-Z_]+)(['"])?:/g;
const argo = process.argv.slice(2).reduce(
	(object, arg) => {
		const argMatch = arg.match(argRegExp);
		const fileMatch = arg.match(fileRegExp);

		if (argMatch) {
			object[argMatch[1]] = argMatch[3];
		} else if (fileMatch) {
			if (object.from === '<stdin>') {
				object.from = arg;
			} else if (object.to === '<stdout>') {
				object.to = arg;
			}
		}

		return object;
	},
	{ from: '<stdin>', to: '<stdout>', opts: 'null' }
);

// get css from command line arguments or stdin
(argo.from === '<stdin>' ? getStdin() : readFile(argo.from))
.then(css => {
	const pluginOpts = JSON.parse(argo.opts.replace(relaxedJsonRegExp, '"$2": '));
	const processOptions = Object.assign({ from: argo.from, to: argo.to || argo.from }, argo.map ? { map: JSON.parse(argo.map) } : {});

	const result = prefersColorScheme.process(css, processOptions, pluginOpts);

	if (argo.to === '<stdout>') {
		return result.css;
	} else {
		return writeFile(argo.to, result.css).then(
			() => `CSS was written to "${argo.to}"`
		)
	}
}).then(
	result => {
		console.log(result);

		process.exit(0);
	},
	error => {
		console.error(error);

		process.exit(1);
	}
);

function readFile(pathname) {
	return new Promise((resolve, reject) => {
		fs.readFile(pathname, 'utf8', (error, data) => {
			if (error) {
				reject(error);
			} else {
				resolve(data);
			}
		});
	});
}

function writeFile(pathname, data) {
	return new Promise((resolve, reject) => {
		fs.writeFile(pathname, data, (error, content) => {
			if (error) {
				reject(error);
			} else {
				resolve(content);
			}
		});
	});
}

function getStdin() {
	return new Promise(resolve => {
		let data = '';

		if (process.stdin.isTTY) {
			resolve(data);
		} else {
			process.stdin.setEncoding('utf8');

			process.stdin.on('readable', () => {
				let chunk;

				while (chunk = process.stdin.read()) {
					data += chunk;
				}
			});

			process.stdin.on('end', () => {
				resolve(data);
			});
		}
	});
}
