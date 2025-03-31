import { IndexInterface, DocumentInterface } from "./type.js";
//import { promise as Promise } from "./polyfill.js";
import { is_function, is_object, is_string } from "./common.js";

export default function(prototype){

    register(prototype, "add");
    register(prototype, "append");
    register(prototype, "search");
    register(prototype, "update");
    register(prototype, "remove");
}

function register(prototype, key){

    prototype[key + "Async"] = function(){

        /** @type {IndexInterface|DocumentInterface} */
        const self = this;
        const args = /*[].slice.call*/(arguments);
        const arg = args[args.length - 1];
        let callback;

        if(is_function(arg)){

            callback = arg;
            delete args[args.length - 1];
        }

        const promise = new Promise(function(resolve){

            setTimeout(function(){

                self.async = true;
                const res = self[key].apply(self, args);
                self.async = false;
                resolve(res);
            });
        });

        if(callback){

            promise.then(callback);
            return this;
        }
        else{

            return promise;
        }
    };
}
