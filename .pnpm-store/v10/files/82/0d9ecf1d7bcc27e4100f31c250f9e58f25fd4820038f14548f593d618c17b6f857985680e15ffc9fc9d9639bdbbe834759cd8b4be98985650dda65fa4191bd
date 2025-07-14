import { IndexInterface } from "./type.js";
import { create_object, get_keys } from "./common.js";

/**
 * @param {!string} str
 * @param {boolean|Array<string|RegExp>=} normalize
 * @param {boolean|string|RegExp=} split
 * @param {boolean=} _collapse
 * @returns {string|Array<string>}
 * @this IndexInterface
 */

export function pipeline(str, normalize, split, _collapse){

    if(str){

        if(normalize){

            str = replace(str, /** @type {Array<string|RegExp>} */ (normalize));
        }

        if(this.matcher){

            str = replace(str, this.matcher);
        }

        if(this.stemmer && (str.length > 1)){

            str = replace(str, this.stemmer);
        }

        if(_collapse && (str.length > 1)){

            str = collapse(str);
        }

        if(split || (split === "")){

            const words = str.split(/** @type {string|RegExp} */ (split));

            return this.filter ? filter(words, this.filter) : words;
        }
    }

    return str;
}

export const regex_whitespace = /[\p{Z}\p{S}\p{P}\p{C}]+/u;
const regex_normalize = /[\u0300-\u036f]/g;

export function normalize(str){

    if(str.normalize){

        str = str.normalize("NFD").replace(regex_normalize, "");
    }

    return str;
}

/**
 * @param {!string} str
 * @param {boolean|Array<string|RegExp>=} normalize
 * @param {boolean|string|RegExp=} split
 * @param {boolean=} _collapse
 * @returns {string|Array<string>}
 */

// FlexSearch.prototype.pipeline = function(str, normalize, split, _collapse){
//
//     if(str){
//
//         if(normalize && str){
//
//             str = replace(str, /** @type {Array<string|RegExp>} */ (normalize));
//         }
//
//         if(str && this.matcher){
//
//             str = replace(str, this.matcher);
//         }
//
//         if(this.stemmer && str.length > 1){
//
//             str = replace(str, this.stemmer);
//         }
//
//         if(_collapse && str.length > 1){
//
//             str = collapse(str);
//         }
//
//         if(str){
//
//             if(split || (split === "")){
//
//                 const words = str.split(/** @type {string|RegExp} */ (split));
//
//                 return this.filter ? filter(words, this.filter) : words;
//             }
//         }
//     }
//
//     return str;
// };

// export function pipeline(str, normalize, matcher, stemmer, split, _filter, _collapse){
//
//     if(str){
//
//         if(normalize && str){
//
//             str = replace(str, normalize);
//         }
//
//         if(matcher && str){
//
//             str = replace(str, matcher);
//         }
//
//         if(stemmer && str.length > 1){
//
//             str = replace(str, stemmer);
//         }
//
//         if(_collapse && str.length > 1){
//
//             str = collapse(str);
//         }
//
//         if(str){
//
//             if(split !== false){
//
//                 str = str.split(split);
//
//                 if(_filter){
//
//                     str = filter(str, _filter);
//                 }
//             }
//         }
//     }
//
//     return str;
// }


/**
 * @param {Array<string>} words
 * @returns {Object<string, string>}
 */

export function init_filter(words){

    const filter = create_object();

    for(let i = 0, length = words.length; i < length; i++){

        filter[words[i]] = 1;
    }

    return filter;
}

/**
 * @param {!Object<string, string>} obj
 * @param {boolean} is_stemmer
 * @returns {Array}
 */

export function init_stemmer_or_matcher(obj, is_stemmer){

    const keys = get_keys(obj);
    const length = keys.length;
    const final = [];

    let removal = "", count = 0;

    for(let i = 0, key, tmp; i < length; i++){

        key = keys[i];
        tmp = obj[key];

        if(tmp){

            final[count++] = regex(is_stemmer ? "(?!\\b)" + key + "(\\b|_)" : key);
            final[count++] = tmp;
        }
        else{

            removal += (removal ? "|" : "") + key;
        }
    }

    if(removal){

        final[count++] = regex(is_stemmer ? "(?!\\b)(" + removal + ")(\\b|_)" : "(" + removal + ")");
        final[count] = "";
    }

    return final;
}


/**
 * @param {!string} str
 * @param {Array} regexp
 * @returns {string}
 */

export function replace(str, regexp){

    for(let i = 0, len = regexp.length; i < len; i += 2){

        str = str.replace(regexp[i], regexp[i + 1]);

        if(!str){

            break;
        }
    }

    return str;
}

/**
 * @param {!string} str
 * @returns {RegExp}
 */

export function regex(str){

    return new RegExp(str, "g");
}

/**
 * Regex: replace(/(?:(\w)(?:\1)*)/g, "$1")
 * @param {!string} string
 * @returns {string}
 */

export function collapse(string){

    let final = "", prev = "";

    for(let i = 0, len = string.length, char; i < len; i++){

        if((char = string[i]) !== prev){

            final += (prev = char);
        }
    }

    return final;
}

// TODO using fast-swap
export function filter(words, map){

    const length = words.length;
    const filtered = [];

    for(let i = 0, count = 0; i < length; i++){

        const word = words[i];

        if(word && !map[word]){

            filtered[count++] = word;
        }
    }

    return filtered;
}

// const chars = {a:1, e:1, i:1, o:1, u:1, y:1};
//
// function collapse_repeating_chars(string){
//
//     let collapsed_string = "",
//         char_prev = "",
//         char_next = "";
//
//     for(let i = 0; i < string.length; i++){
//
//         const char = string[i];
//
//         if(char !== char_prev){
//
//             if(i && (char === "h")){
//
//                 if((chars[char_prev] && chars[char_next]) || (char_prev === " ")){
//
//                     collapsed_string += char;
//                 }
//             }
//             else{
//
//                 collapsed_string += char;
//             }
//         }
//
//         char_next = (
//
//             (i === (string.length - 1)) ?
//
//                 ""
//             :
//                 string[i + 1]
//         );
//
//         char_prev = char;
//     }
//
//     return collapsed_string;
// }
