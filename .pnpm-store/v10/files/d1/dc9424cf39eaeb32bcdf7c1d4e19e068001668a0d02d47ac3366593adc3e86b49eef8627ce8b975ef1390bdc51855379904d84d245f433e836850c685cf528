import { POLYFILL, SUPPORT_ASYNC } from "./config.js";

export let promise = Promise;

if(POLYFILL){

    Object.assign || (Object.assign = function(){

        const args = arguments;
        const size = args.length;
        const obj = args[0];

        for(let x = 1, current, keys, length; x < size; x++){

            current = args[x];
            keys = Object.keys(current);
            length = keys.length;

            for(let i = 0, key; i < length; i++){

                key = keys[i];
                obj[key] = current[key];
            }
        }

        return obj;
    });

    // Object.values || (Object.values = function(obj){
    //
    //     const keys = Object.keys(obj);
    //     const length = keys.length;
    //     const values = new Array(length);
    //
    //     for(let x = 0; x < length; x++){
    //
    //         values[x] = obj[keys[x]];
    //     }
    //
    //     return values;
    // });

    if(SUPPORT_ASYNC && !promise){

        /**
         * @param {Function} fn
         * @constructor
         */

        function SimplePromise(fn){

            this.callback = null;

            const self = this;

            fn(function(val){

                if(self.callback){

                    self.callback(val);
                    // self.callback = null;
                    // self = null;
                }
            });
        }

        /**
         * @param {Function} callback
         */

        SimplePromise.prototype.then = function(callback){

            this.callback = callback;
        };

        promise = SimplePromise;
    }
}
