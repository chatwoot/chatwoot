//import { promise as Promise } from "../polyfill.js";
import { create_object, is_function, is_object, is_string } from "../common.js";
import handler from "./handler.js";

let pid = 0;

/**
 * @param {Object=} options
 * @constructor
 */

function WorkerIndex(options){

    if(!(this instanceof WorkerIndex)) {

        return new WorkerIndex(options);
    }

    let opt;

    if(options){

        if(is_function(opt = options["encode"])){

            options["encode"] = opt.toString();
        }
    }
    else{

        options = {};
    }

    // the factory is the outer wrapper from the build
    // we use "self" as a trap for node.js

    let factory = (self||window)["_factory"];

    if(factory){

        factory = factory.toString();
    }

    const is_node_js = self["exports"];
    const _self = this;

    this.worker = create(factory, is_node_js, options["worker"]);
    this.resolver = create_object();

    if(!this.worker){

        return;
    }

    if(is_node_js){

        this.worker["on"]("message", function(msg){

            _self.resolver[msg["id"]](msg["msg"]) ;
            delete _self.resolver[msg["id"]];
        });
    }
    else{

        this.worker.onmessage = function(msg){

            msg = msg["data"];
            _self.resolver[msg["id"]](msg["msg"]);
            delete _self.resolver[msg["id"]];
        };
    }

    this.worker.postMessage({

        "task": "init",
        "factory": factory,
        "options": options
    });
}

export default WorkerIndex;

register("add");
register("append");
register("search");
register("update");
register("remove");

function register(key){

    WorkerIndex.prototype[key] =
    WorkerIndex.prototype[key + "Async"] = function(){

        const self = this;
        const args = [].slice.call(arguments);
        const arg = args[args.length - 1];
        let callback;

        if(is_function(arg)){

            callback = arg;
            args.splice(args.length - 1, 1);
        }

        const promise = new Promise(function(resolve){

            setTimeout(function(){

                self.resolver[++pid] = resolve;
                self.worker.postMessage({

                    "task": key,
                    "id": pid,
                    "args": args
                });
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

function create(factory, is_node_js, worker_path){

    let worker

    try{

        worker = is_node_js ?

            eval('new (require("worker_threads")["Worker"])("../dist/node/node.js")')
        :(
            factory ?

                new Worker(URL.createObjectURL(

                    new Blob([

                        "onmessage=" + handler.toString()

                    ], { "type": "text/javascript" })
                ))
            :
                new Worker(is_string(worker_path) ? worker_path : "worker/worker.js", { type: "module" })
        );
    }
    catch(e){}

    return worker;
}