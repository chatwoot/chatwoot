import { IndexInterface } from "../../type.js";
import { pipeline, normalize, regex_whitespace } from "../../lang.js";

export const rtl = false;
export const tokenize = "";
export default {
    encode: encode,
    rtl: rtl,
    tokenize: tokenize
}

/**
 * @this IndexInterface
 */

export function encode(str){

    return pipeline.call(

        this,
        /* string: */ ("" + str).toLowerCase(),
        /* normalize: */ false,
        /* split: */ regex_whitespace,
        /* collapse: */ false
    );
}
