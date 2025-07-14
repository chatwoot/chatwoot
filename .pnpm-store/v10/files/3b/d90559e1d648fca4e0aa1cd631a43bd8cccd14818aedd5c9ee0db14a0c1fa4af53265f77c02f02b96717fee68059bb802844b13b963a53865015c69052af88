import { IndexInterface } from "../../type.js";
import { pipeline } from "../../lang.js";

export const rtl = true;
export const tokenize = "";
export default {
    encode: encode,
    rtl: rtl
}

const regex = /[\x00-\x7F]+/g;
const split = /\s+/;

/**
 * @this IndexInterface
 */

export function encode(str){

    return pipeline.call(

        this,
        /* string: */ str.replace(regex, " "),
        /* normalize: */ false,
        /* split: */ split,
        /* collapse: */ false
    );
}
