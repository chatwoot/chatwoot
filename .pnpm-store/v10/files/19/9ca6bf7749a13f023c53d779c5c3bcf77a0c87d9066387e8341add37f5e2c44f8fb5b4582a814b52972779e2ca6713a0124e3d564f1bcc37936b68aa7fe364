import { IndexInterface } from "../../type.js";
import { pipeline } from "../../lang.js";

export const rtl = false;
export const tokenize = "strict";
export default {
    encode: encode,
    rtl: rtl,
    tokenize: tokenize
}

const regex = /[\x00-\x7F]+/g;

/**
 * @this IndexInterface
 */

export function encode(str){

    return pipeline.call(

        this,
        /* string: */ str.replace(regex, ""),
        /* normalize: */ false,
        /* split: */ "",
        /* collapse: */ false
    );
}
