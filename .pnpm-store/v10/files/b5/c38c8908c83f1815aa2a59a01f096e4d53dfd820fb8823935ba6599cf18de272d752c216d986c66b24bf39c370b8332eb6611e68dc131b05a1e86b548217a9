import { DEBUG, SUPPORT_ASYNC, SUPPORT_CACHE } from "./config";
import { searchCache } from "./cache";

/**
 * @constructor
 * @abstract
 */

function Engine(index){

    if(DEBUG){

        //if(this.constructor === Engine){
        if(this instanceof Engine){

            throw new Error("Can't instantiate abstract class!");
        }
    }

    if(SUPPORT_CACHE){

        index.prototype.searchCache = searchCache;
    }

    if(SUPPORT_ASYNC){

        index.prototype.addAsync = addAsync;
        index.prototype.appendAsync = appendAsync;
        index.prototype.searchAsync = searchAsync;
        index.prototype.updateAsync = updateAsync;
        index.prototype.removeAsync = removeAsync;
    }
}

if(SUPPORT_CACHE){

    Engine.prototype.searchCache = searchCache;
}

if(SUPPORT_ASYNC){

    Engine.prototype.addAsync = addAsync;
    Engine.prototype.appendAsync = appendAsync;
    Engine.prototype.searchAsync = searchAsync;
    Engine.prototype.updateAsync = updateAsync;
    Engine.prototype.removeAsync = removeAsync;
}