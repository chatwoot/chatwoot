function r(m){return m && m.default || m;}
module.exports = global.fetch = global.fetch || (
	typeof process=='undefined' ? r(require('unfetch')) : (function(url, opts) {
		return r(require('node-fetch'))(String(url).replace(/^\/\//g,'https://'), opts);
	})
);
