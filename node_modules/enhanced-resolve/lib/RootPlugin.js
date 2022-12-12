/*
	MIT License http://www.opensource.org/licenses/mit-license.php
	Author Ivan Kopeykin @vankop
*/

"use strict";

/** @typedef {import("./Resolver")} Resolver */
/** @typedef {import("./Resolver").ResolveStepHook} ResolveStepHook */

class RootPlugin {
	/**
	 * @param {string | ResolveStepHook} source source hook
	 * @param {Array<string>} root roots
	 * @param {string | ResolveStepHook} target target hook
	 * @param {boolean=} ignoreErrors ignore error during resolving of root paths
	 */
	constructor(source, root, target, ignoreErrors) {
		this.root = root;
		this.source = source;
		this.target = target;
		this._ignoreErrors = ignoreErrors;
	}

	/**
	 * @param {Resolver} resolver the resolver
	 * @returns {void}
	 */
	apply(resolver) {
		const target = resolver.ensureHook(this.target);

		resolver
			.getHook(this.source)
			.tapAsync("RootPlugin", (request, resolveContext, callback) => {
				const req = request.request;
				if (!req) return callback();
				if (!req.startsWith("/")) return callback();

				const path = resolver.join(this.root, req.slice(1));
				const obj = Object.assign(request, {
					path,
					relativePath: request.relativePath && path
				});
				resolver.doResolve(
					target,
					obj,
					`root path ${this.root}`,
					resolveContext,
					this._ignoreErrors
						? (err, result) => {
								if (err) {
									if (resolveContext.log) {
										resolveContext.log(
											`Ignored fatal error while resolving root path:\n${err}`
										);
									}
									return callback();
								}
								if (result) return callback(null, result);
								callback();
						  }
						: callback
				);
			});
	}
}

module.exports = RootPlugin;
