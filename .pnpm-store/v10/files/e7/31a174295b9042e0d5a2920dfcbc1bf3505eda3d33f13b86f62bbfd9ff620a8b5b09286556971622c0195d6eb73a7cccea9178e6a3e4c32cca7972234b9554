import { IndexInterface } from "../../type.js";
import { regex, replace, collapse } from "../../lang.js";
import { encode as encode_advanced } from "./advanced.js";

export const rtl = false;
export const tokenize = "";
export default {
    encode: encode,
    rtl: rtl,
    tokenize: tokenize
}

// Soundex Normalization

const prefix = "(?!\\b)";
const //soundex_b = regex(prefix + "p"),
    // soundex_s = regex(prefix + "z"),
    // soundex_k = regex(prefix + "[cgq]"),
    // soundex_m = regex(prefix + "n"),
    // soundex_t = regex(prefix + "d"),
    // soundex_f = regex(prefix + "[vw]"),
    //regex_vowel = regex(prefix + "[aeiouy]");
    regex_vowel = regex(prefix + "[aeo]");

const pairs = [

    // soundex_b, "b",
    // soundex_s, "s",
    // soundex_k, "k",
    // soundex_m, "m",
    // soundex_t, "t",
    // soundex_f, "f",
    // regex("(?![aeiouy])h(?![aeiouy])"), "",
    // regex("(?!^[aeiouy])h(?!^[aeiouy])"), "",
    regex_vowel, ""
];

/**
 * @this IndexInterface
 */

export function encode(str){

    if(str){

        str = encode_advanced.call(this, str, /* skip post-processing: */ true);

        if(str.length > 1){

            //str = replace(str, pairs);
            str = str.replace(regex_vowel, "");
        }

        if(str.length > 1){

            str = collapse(str);
        }

        if(str){

            str = str.split(" ");
        }
    }

    return str;
}
