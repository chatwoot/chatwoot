const path = require('path')
const fs = require('fs')

function getVuePackageVersion() {
	try {
		const pkg = require('vue/package.json')
		return pkg.version
	} catch (error) {
		return 'unknown'
	}
}

function updateIndexForVue3() {
	// commonjs
	const indexPath = path.join(__dirname, './index.cjs.js')
	const indexContent = `
  const Vue = require('vue')
  
  module.exports.h = Vue.h
  module.exports.createApp = Vue.createApp
  module.exports.resolveComponent = Vue.resolveComponent
  module.exports.isVue3 = true
  module.exports.Vue2 = function(){}
  `
	fs.writeFile(indexPath, indexContent, err => {
		if (err) {
			console.error(err)
		}
	})

	// esm
	const indexPathESM = path.join(__dirname, './index.esm.js')
	const indexContentESM = `
  export { h, resolveComponent, createApp } from 'vue'
  export const isVue3 = true
  export const Vue2 = () => {}
  `

	fs.writeFile(indexPathESM, indexContentESM, err => {
		if (err) {
			console.error(err)
		}
	})
}

const version = getVuePackageVersion()

if (version.startsWith('3.')) {
	updateIndexForVue3()
}
