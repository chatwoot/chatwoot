/**
 * @interface
 */

export function IndexInterface(){

    this.cache = null;
    this.matcher = null;
    this.stemmer = null;
    this.filter = null;
}

/**
 * @param {!string} str
 * @param {boolean|Array<string|RegExp>=} normalize
 * @param {boolean|string|RegExp=} split
 * @param {boolean=} collapse
 * @returns {string|Array<string>}
 */

//IndexInterface.prototype.pipeline;

/**
 * @param {!number|string} id
 * @param {!string} content
 */

IndexInterface.prototype.add;

/**
 * @param {!number|string} id
 * @param {!string} content
 */

IndexInterface.prototype.append;

/**
 * @param {!string|Object} query
 * @param {number|Object=} limit
 * @param {Object=} options
 * @returns {Array<number|string>}
 */

IndexInterface.prototype.search;

/**
 * @param {!number|string} id
 * @param {!string} content
 */

IndexInterface.prototype.update;

/**
 * @param {!number|string} id
 */

IndexInterface.prototype.remove;

/**
 * @interface
 */

export function DocumentInterface(){

    this.field = null;

    /** @type IndexInterface */
    this.index = null;
}
