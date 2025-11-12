import { IndexInterface, DocumentInterface } from "./type.js";
import { create_object, is_object } from "./common.js";

/**
 * @param {boolean|number=} limit
 * @constructor
 */

function CacheClass(limit){

    /** @private */
    this.limit = (limit !== true) && limit;

    /** @private */
    this.cache = create_object();

    /** @private */
    this.queue = [];

    //this.clear();
}

export default CacheClass;

/**
 * @param {string|Object} query
 * @param {number|Object=} limit
 * @param {Object=} options
 * @this {IndexInterface}
 * @returns {Array<number|string>}
 */

export function searchCache(query, limit, options){

    if(is_object(query)){

        query = query["query"];
    }

    let cache = this.cache.get(query);

    if(!cache){

        cache = this.search(query, limit, options);
        this.cache.set(query, cache);
    }

    return cache;
}

// CacheClass.prototype.clear = function(){
//
//     /** @private */
//     this.cache = create_object();
//
//     /** @private */
//     this.queue = [];
// };

CacheClass.prototype.set = function(key, value){

    if(!this.cache[key]){

        // it is just a shame that native function array.shift() performs so bad

        // const length = this.queue.length;
        //
        // this.queue[length] = key;
        //
        // if(length === this.limit){
        //
        //     delete this.cache[this.queue.shift()];
        // }

        // the same bad performance

        // this.queue.unshift(key);
        //
        // if(this.queue.length === this.limit){
        //
        //     this.queue.pop();
        // }

        // fast implementation variant

        // let length = this.queue.length;
        //
        // if(length === this.limit){
        //
        //     length--;
        //
        //     delete this.cache[this.queue[0]];
        //
        //     for(let x = 0; x < length; x++){
        //
        //         this.queue[x] = this.queue[x + 1];
        //     }
        // }
        //
        // this.queue[length] = key;

        // current fastest implementation variant
        // theoretically that should not perform better compared to the example above

        let length = this.queue.length;

        if(length === this.limit){

            delete this.cache[this.queue[length - 1]];
        }
        else{

            length++;
        }

        for(let x = length - 1; x > 0; x--){

            this.queue[x] = this.queue[x - 1];
        }

        this.queue[0] = key;
    }

    this.cache[key] = value;
};

CacheClass.prototype.get = function(key){

    const cache = this.cache[key];

    if(this.limit && cache){

        // probably the indexOf() method performs faster when matched content is on front (left-to-right)
        // using lastIndexOf() does not help, it performs almost slower

        const pos = this.queue.indexOf(key);

        // if(pos < this.queue.length - 1){
        //
        //     const tmp = this.queue[pos];
        //     this.queue[pos] = this.queue[pos + 1];
        //     this.queue[pos + 1] = tmp;
        // }

        if(pos){

            const tmp = this.queue[pos - 1];
            this.queue[pos - 1] = this.queue[pos];
            this.queue[pos] = tmp;
        }
    }

    return cache;
};

CacheClass.prototype.del = function(id){

    for(let i = 0, item, key; i < this.queue.length; i++){

        key = this.queue[i];
        item = this.cache[key];

        if(item.indexOf(id) !== -1){

            this.queue.splice(i--, 1);
            delete this.cache[key];
        }
    }
};
