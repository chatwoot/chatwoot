/**!
 * FlexSearch.js
 * Copyright 2018-2021 Nextapps GmbH
 * Author: Thomas Wilkerling
 * Licence: Apache-2.0
 * https://github.com/nextapps-de/flexsearch
 */

import {

    SUPPORT_ENCODER,
    SUPPORT_CACHE,
    SUPPORT_ASYNC,
    SUPPORT_SUGGESTION,
    SUPPORT_SERIALIZE

} from "./config.js";

import { IndexInterface } from "./type.js";
import { encode as default_encoder } from "./lang/latin/default.js";
import { create_object, create_object_array, concat, sort_by_length_down, is_array, is_string, is_object, parse_option } from "./common.js";
import { pipeline, init_stemmer_or_matcher, init_filter } from "./lang.js";
import { global_lang, global_charset } from "./global.js";
import apply_async from "./async.js";
import { intersect } from "./intersect.js";
import Cache, { searchCache } from "./cache.js";
import apply_preset from "./preset.js";
import { exportIndex, importIndex } from "./serialize.js";

/**
 * @constructor
 * @implements IndexInterface
 * @param {Object=} options
 * @param {Object=} _register
 * @return {Index}
 */

function Index(options, _register){

    if(!(this instanceof Index)) {

        return new Index(options);
    }

    let charset, lang, tmp;

    if(options){

        if(SUPPORT_ENCODER){

            options = apply_preset(options);
        }

        charset = options["charset"];
        lang = options["lang"];

        if(is_string(charset)){

            if(charset.indexOf(":") === -1){

                charset += ":default";
            }

            charset = global_charset[charset];
        }

        if(is_string(lang)){

            lang = global_lang[lang];
        }
    }
    else{

        options = {};
    }

    let resolution, optimize, context = options["context"] || {};

    this.encode = options["encode"] || (charset && charset.encode) || default_encoder;
    this.register = _register || create_object();
    this.resolution = resolution = options["resolution"] || 9;
    this.tokenize = tmp = (charset && charset.tokenize) || options["tokenize"] || "strict";
    this.depth = (tmp === "strict") && context["depth"];
    this.bidirectional = parse_option(context["bidirectional"], true);
    this.optimize = optimize = parse_option(options["optimize"], true);
    this.fastupdate = parse_option(options["fastupdate"], true);
    this.minlength = options["minlength"] || 1;
    this.boost = options["boost"];

    // when not using the memory strategy the score array should not pre-allocated to its full length

    this.map = optimize ? create_object_array(resolution) : create_object();
    this.resolution_ctx = resolution = context["resolution"] || 1;
    this.ctx = optimize ? create_object_array(resolution) : create_object();
    this.rtl = (charset && charset.rtl) || options["rtl"];
    this.matcher = (tmp = options["matcher"] || (lang && lang.matcher)) && init_stemmer_or_matcher(tmp, false);
    this.stemmer = (tmp = options["stemmer"] || (lang && lang.stemmer)) && init_stemmer_or_matcher(tmp, true);
    this.filter = (tmp = options["filter"] || (lang && lang.filter)) && init_filter(tmp);

    if(SUPPORT_CACHE){

        this.cache = (tmp = options["cache"]) && new Cache(tmp);
    }
}

export default Index;

//Index.prototype.pipeline = pipeline;

/**
 * @param {!number|string} id
 * @param {!string} content
 */

Index.prototype.append = function(id, content){

    return this.add(id, content, true);
};

/**
 * @param {!number|string} id
 * @param {!string} content
 * @param {boolean=} _append
 * @param {boolean=} _skip_update
 */

Index.prototype.add = function(id, content, _append, _skip_update){

    if(content && (id || (id === 0))){

        if(!_skip_update && !_append && this.register[id]){

            return this.update(id, content);
        }

        content = this.encode(content);
        const length = content.length;

        if(length){

            // check context dupes to skip all contextual redundancy along a document

            const dupes_ctx = create_object();
            const dupes = create_object();
            const depth = this.depth;
            const resolution = this.resolution;

            for(let i = 0; i < length; i++){

                let term = content[this.rtl ? length - 1 - i : i];
                let term_length = term.length;

                // skip dupes will break the context chain

                if(term && (term_length >= this.minlength) && (depth || !dupes[term])){

                    let score = get_score(resolution, length, i);
                    let token = "";

                    switch(this.tokenize){

                        case "full":

                            if(term_length > 3){

                                for(let x = 0; x < term_length; x++){

                                    for(let y = term_length; y > x; y--){

                                        if((y - x) >= this.minlength){

                                            const partial_score = get_score(resolution, length, i, term_length, x);
                                            token = term.substring(x, y);
                                            this.push_index(dupes, token, partial_score, id, _append);
                                        }
                                    }
                                }

                                break;
                            }

                            // fallthrough to next case when term length < 4

                        case "reverse":

                            // skip last round (this token exist already in "forward")

                            if(term_length > 2){

                                for(let x = term_length - 1; x > 0; x--){

                                    token = term[x] + token;

                                    if(token.length >= this.minlength){

                                        const partial_score = get_score(resolution, length, i, term_length, x);
                                        this.push_index(dupes, token, partial_score, id, _append);
                                    }
                                }

                                token = "";
                            }

                            // fallthrough to next case to apply forward also

                        case "forward":

                            if(term_length > 1){

                                for(let x = 0; x < term_length; x++){

                                    token += term[x];

                                    if(token.length >= this.minlength){

                                        this.push_index(dupes, token, score, id, _append);
                                    }
                                }

                                break;
                            }

                            // fallthrough to next case when token has a length of 1

                        default:
                        // case "strict":

                            if(this.boost){

                                score = Math.min((score / this.boost(content, term, i)) | 0, resolution - 1);
                            }

                            this.push_index(dupes, term, score, id, _append);

                            // context is just supported by tokenizer "strict"

                            if(depth){

                                if((length > 1) && (i < (length - 1))){

                                    // check inner dupes to skip repeating words in the current context

                                    const dupes_inner = create_object();
                                    const resolution = this.resolution_ctx;
                                    const keyword = term;
                                    const size = Math.min(depth + 1, length - i);

                                    dupes_inner[keyword] = 1;

                                    for(let x = 1; x < size; x++){

                                        term = content[this.rtl ? length - 1 - i - x : i + x];

                                        if(term && (term.length >= this.minlength) && !dupes_inner[term]){

                                            dupes_inner[term] = 1;

                                            const context_score = get_score(resolution + ((length / 2) > resolution ? 0 : 1), length, i, size - 1, x - 1);
                                            const swap = this.bidirectional && (term > keyword);
                                            this.push_index(dupes_ctx, swap ? keyword : term, context_score, id, _append, swap ? term : keyword);
                                        }
                                    }
                                }
                            }
                    }
                }
            }

            this.fastupdate || (this.register[id] = 1);
        }
    }

    return this;
};

/**
 * @param {number} resolution
 * @param {number} length
 * @param {number} i
 * @param {number=} term_length
 * @param {number=} x
 * @returns {number}
 */

function get_score(resolution, length, i, term_length, x){

    // console.log("resolution", resolution);
    // console.log("length", length);
    // console.log("term_length", term_length);
    // console.log("i", i);
    // console.log("x", x);
    // console.log((resolution - 1) / (length + (term_length || 0)) * (i + (x || 0)) + 1);

    // the first resolution slot is reserved for the best match,
    // when a query matches the first word(s).

    // also to stretch score to the whole range of resolution, the
    // calculation is shift by one and cut the floating point.
    // this needs the resolution "1" to be handled additionally.

    // do not stretch the resolution more than the term length will
    // improve performance and memory, also it improves scoring in
    // most cases between a short document and a long document

    return i && (resolution > 1) ? (

        (length + (term_length || 0)) <= resolution ?

            i + (x || 0)
        :
            ((resolution - 1) / (length + (term_length || 0)) * (i + (x || 0)) + 1) | 0
    ):
        0;
}

/**
 * @private
 * @param dupes
 * @param value
 * @param score
 * @param id
 * @param {boolean=} append
 * @param {string=} keyword
 */

Index.prototype.push_index = function(dupes, value, score, id, append, keyword){

    let arr = keyword ? this.ctx : this.map;

    if(!dupes[value] || (keyword && !dupes[value][keyword])){

        if(this.optimize){

            arr = arr[score];
        }

        if(keyword){

            dupes = dupes[value] || (dupes[value] = create_object());
            dupes[keyword] = 1;

            arr = arr[keyword] || (arr[keyword] = create_object());
        }
        else{

            dupes[value] = 1;
        }

        arr = arr[value] || (arr[value] = []);

        if(!this.optimize){

            arr = arr[score] || (arr[score] = []);
        }

        if(!append || (arr.indexOf(id) === -1)){

            arr[arr.length] = id;

            // add a reference to the register for fast updates

            if(this.fastupdate){

                const tmp =  this.register[id] || (this.register[id] = []);
                tmp[tmp.length] = arr;
            }
        }
    }
}

/**
 * @param {string|Object} query
 * @param {number|Object=} limit
 * @param {Object=} options
 * @returns {Array<number|string>}
 */

Index.prototype.search = function(query, limit, options){

    if(!options){

        if(!limit && is_object(query)){

            options = /** @type {Object} */ (query);
            query = options["query"];
        }
        else if(is_object(limit)){

            options = /** @type {Object} */ (limit);
        }
    }

    let result = [];
    let length;
    let context, suggest, offset = 0;

    if(options){

        limit = options["limit"];
        offset = options["offset"] || 0;
        context = options["context"];
        suggest = SUPPORT_SUGGESTION && options["suggest"];
    }

    if(query){

        query = /** @type {Array} */ (this.encode(query));
        length = query.length;

        // TODO: solve this in one single loop below

        if(length > 1){

            const dupes = create_object();
            const query_new = [];

            for(let i = 0, count = 0, term; i < length; i++){

                term = query[i];

                if(term && (term.length >= this.minlength) && !dupes[term]){

                    // this fast path just could applied when not in memory-optimized mode

                    if(!this.optimize && !suggest && !this.map[term]){

                        // fast path "not found"

                        return result;
                    }
                    else{

                        query_new[count++] = term;
                        dupes[term] = 1;
                    }
                }
            }

            query = query_new;
            length = query.length;
        }
    }

    if(!length){

        return result;
    }

    limit || (limit = 100);

    let depth = this.depth && (length > 1) && (context !== false);
    let index = 0, keyword;

    if(depth){

        keyword = query[0];
        index = 1;
    }
    else{

        if(length > 1){

            query.sort(sort_by_length_down);
        }
    }

    for(let arr, term; index < length; index++){

        term = query[index];

        // console.log(keyword);
        // console.log(term);
        // console.log("");

        if(depth){

            arr = this.add_result(result, suggest, limit, offset, length === 2, term, keyword);

            // console.log(arr);
            // console.log(result);

            // when suggestion enabled just forward keyword if term was found
            // as long as the result is empty forward the pointer also

            if(!suggest || (arr !== false) || !result.length){

                keyword = term;
            }
        }
        else{

            arr = this.add_result(result, suggest, limit, offset, length === 1, term);
        }

        if(arr){

            return /** @type {Array<number|string>} */ (arr);
        }

        // apply suggestions on last loop or fallback

        if(suggest && (index === length - 1)){

            let length = result.length;

            if(!length){

                if(depth){

                    // fallback to non-contextual search when no result was found

                    depth = 0;
                    index = -1;

                    continue;
                }

                return result;
            }
            else if(length === 1){

                // fast path optimization

                return single_result(result[0], limit, offset);
            }
        }
    }

    return intersect(result, limit, offset, suggest);
};

/**
 * Returns an array when the result is done (to stop the process immediately),
 * returns false when suggestions is enabled and no result was found,
 * or returns nothing when a set was pushed successfully to the results
 *
 * @private
 * @param {Array} result
 * @param {Array} suggest
 * @param {number} limit
 * @param {number} offset
 * @param {boolean} single_term
 * @param {string} term
 * @param {string=} keyword
 * @return {Array<Array<string|number>>|boolean|undefined}
 */

Index.prototype.add_result = function(result, suggest, limit, offset, single_term, term, keyword){

    let word_arr = [];
    let arr = keyword ? this.ctx : this.map;

    if(!this.optimize){

        arr = get_array(arr, term, keyword, this.bidirectional);
    }

    if(arr){

        let count = 0;
        const arr_len = Math.min(arr.length, keyword ? this.resolution_ctx : this.resolution);

        // relevance:
        for(let x = 0, size = 0, tmp, len; x < arr_len; x++){

            tmp = arr[x];

            if(tmp){

                if(this.optimize){

                    tmp = get_array(tmp, term, keyword, this.bidirectional);
                }

                if(offset){

                    if(tmp && single_term){

                        len = tmp.length;

                        if(len <= offset){

                            offset -= len;
                            tmp = null;
                        }
                        else{

                            tmp = tmp.slice(offset);
                            offset = 0;
                        }
                    }
                }

                if(tmp){

                    // keep score (sparse array):
                    //word_arr[x] = tmp;

                    // simplified score order:
                    word_arr[count++] = tmp;

                    if(single_term){

                        size += tmp.length;

                        if(size >= limit){

                            // fast path optimization

                            break;
                        }
                    }
                }
            }
        }

        if(count){

            if(single_term){

                // fast path optimization
                // offset was already applied at this point

                return single_result(word_arr, limit, 0);
            }

            result[result.length] = word_arr;
            return;
        }
    }

    // return an empty array will stop the loop,
    // to prevent stop when using suggestions return a false value

    return !suggest && word_arr;
};

function single_result(result, limit, offset){

    if(result.length === 1){

        result = result[0];
    }
    else{

        result = concat(result);
    }

    return offset || (result.length > limit) ?

        result.slice(offset, offset + limit)
    :
        result;
}

function get_array(arr, term, keyword, bidirectional){

    if(keyword){

        // the frequency of the starting letter is slightly less
        // on the last half of the alphabet (m-z) in almost every latin language,
        // so we sort downwards (https://en.wikipedia.org/wiki/Letter_frequency)

        const swap = bidirectional && (term > keyword);

        arr = arr[swap ? term : keyword];
        arr = arr && arr[swap ? keyword : term];
    }
    else{

        arr = arr[term];
    }

    return arr;
}

Index.prototype.contain = function(id){

    return !!this.register[id];
};

Index.prototype.update = function(id, content){

    return this.remove(id).add(id, content);
};

/**
 * @param {boolean=} _skip_deletion
 */

Index.prototype.remove = function(id, _skip_deletion){

    const refs = this.register[id];

    if(refs){

        if(this.fastupdate){

            // fast updates performs really fast but did not fully cleanup the key entries

            for(let i = 0, tmp; i < refs.length; i++){

                tmp = refs[i];
                tmp.splice(tmp.indexOf(id), 1);
            }
        }
        else{

            remove_index(this.map, id, this.resolution, this.optimize);

            if(this.depth){

                remove_index(this.ctx, id, this.resolution_ctx, this.optimize);
            }
        }

        _skip_deletion || delete this.register[id];

        if(SUPPORT_CACHE && this.cache){

            this.cache.del(id);
        }
    }

    return this;
};

/**
 * @param map
 * @param id
 * @param res
 * @param optimize
 * @param {number=} resolution
 * @return {number}
 */

function remove_index(map, id, res, optimize, resolution){

    let count = 0;

    if(is_array(map)){

        // the first array is the score array in both strategies

        if(!resolution){

            resolution = Math.min(map.length, res);

            for(let x = 0, arr; x < resolution; x++){

                arr = map[x];

                if(arr){

                    count = remove_index(arr, id, res, optimize, resolution);

                    if(!optimize && !count){

                        // when not memory optimized the score index should removed

                        delete map[x];
                    }
                }
            }
        }
        else{

            const pos = map.indexOf(id);

            if(pos !== -1){

                // fast path, when length is 1 or lower then the whole field gets deleted

                if(map.length > 1){

                    map.splice(pos, 1);
                    count++;
                }
            }
            else{

                count++;
            }
        }
    }
    else{

        for(let key in map){

            count = remove_index(map[key], id, res, optimize, resolution);

            if(!count){

                delete map[key];
            }
        }
    }

    return count;
}

if(SUPPORT_CACHE){

    Index.prototype.searchCache = searchCache;
}

if(SUPPORT_SERIALIZE){

    Index.prototype.export = exportIndex;
    Index.prototype.import = importIndex;
}

if(SUPPORT_ASYNC){

    apply_async(Index.prototype);
}
