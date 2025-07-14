import { DEBUG } from "./config.js";
import { is_string } from "./common.js";

/**
 * @enum {Object}
 * @const
 */

const preset = {

    "memory": {
        charset: "latin:extra",
        //tokenize: "strict",
        resolution: 3,
        //threshold: 0,
        minlength: 4,
        fastupdate: false
    },

    "performance": {
        //charset: "latin",
        //tokenize: "strict",
        resolution: 3,
        minlength: 3,
        //fastupdate: true,
        optimize: false,
        //fastupdate: true,
        context: {
            depth: 2,
            resolution: 1
            //bidirectional: false
        }
    },

    "match": {
        charset: "latin:extra",
        tokenize: "reverse",
        //resolution: 9,
        //threshold: 0
    },

    "score": {
        charset: "latin:advanced",
        //tokenize: "strict",
        resolution: 20,
        minlength: 3,
        context: {
            depth: 3,
            resolution: 9,
            //bidirectional: true
        }
    },

    "default": {
        // charset: "latin:default",
        // tokenize: "strict",
        // resolution: 3,
        // threshold: 0,
        // depth: 3
    },

    // "fast": {
    //     //charset: "latin",
    //     //tokenize: "strict",
    //     threshold: 8,
    //     resolution: 9,
    //     depth: 1
    // }
};

export default function apply_preset(options){

    if(is_string(options)){

        if(DEBUG && !preset[options]){

            console.warn("Preset not found: " + options);
        }

        options = preset[options];
    }
    else{

        const preset = options["preset"];

        if(preset){

            if(DEBUG && !preset[preset]){

                console.warn("Preset not found: " + preset);
            }

            options = Object.assign({}, preset[preset], /** @type {Object} */ (options));
        }
    }

    return options;
}