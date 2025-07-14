import { create_object, concat } from "./common.js";

/**
 * Implementation based on Array.indexOf() provides better performance,
 * but it needs at least one word in the query which is less frequent.
 * Also on large indexes it does not scale well performance-wise.
 * This strategy also lacks of suggestion capabilities (matching & sorting).
 *
 * @param arrays
 * @param limit
 * @param offset
 * @param {boolean|Array=} suggest
 * @returns {Array}
 */

// export function intersect(arrays, limit, offset, suggest) {
//
//     const length = arrays.length;
//     let result = [];
//     let check;
//
//     // determine shortest array and collect results
//     // from the sparse relevance arrays
//
//     let smallest_size;
//     let smallest_arr;
//     let smallest_index;
//
//     for(let x = 0; x < length; x++){
//
//         const arr = arrays[x];
//         const len = arr.length;
//
//         let size = 0;
//
//         for(let y = 0, tmp; y < len; y++){
//
//             tmp = arr[y];
//
//             if(tmp){
//
//                 size += tmp.length;
//             }
//         }
//
//         if(!smallest_size || (size < smallest_size)){
//
//             smallest_size = size;
//             smallest_arr = arr;
//             smallest_index = x;
//         }
//     }
//
//     smallest_arr = smallest_arr.length === 1 ?
//
//         smallest_arr[0]
//     :
//         concat(smallest_arr);
//
//     if(suggest){
//
//         suggest = [smallest_arr];
//         check = create_object();
//     }
//
//     let size = 0;
//     let steps = 0;
//
//     // process terms in reversed order often results in better performance.
//     // the outer loop must be the words array, using the
//     // smallest array here disables the "fast fail" optimization.
//
//     for(let x = length - 1; x >= 0; x--){
//
//         if(x !== smallest_index){
//
//             steps++;
//
//             const word_arr = arrays[x];
//             const word_arr_len = word_arr.length;
//             const new_arr = [];
//
//             let count = 0;
//
//             for(let z = 0, id; z < smallest_arr.length; z++){
//
//                 id = smallest_arr[z];
//
//                 let found;
//
//                 // process relevance in forward order (direction is
//                 // important for adding IDs during the last round)
//
//                 for(let y = 0; y < word_arr_len; y++){
//
//                     const arr = word_arr[y];
//
//                     if(arr.length){
//
//                         found = arr.indexOf(id) !== -1;
//
//                         if(found){
//
//                             // check if in last round
//
//                             if(steps === length - 1){
//
//                                 if(offset){
//
//                                     offset--;
//                                 }
//                                 else{
//
//                                     result[size++] = id;
//
//                                     if(size === limit){
//
//                                         // fast path "end reached"
//
//                                         return result;
//                                     }
//                                 }
//
//                                 if(suggest){
//
//                                     check[id] = 1;
//                                 }
//                             }
//
//                             break;
//                         }
//                     }
//                 }
//
//                 if(found){
//
//                     new_arr[count++] = id;
//                 }
//             }
//
//             if(suggest){
//
//                 suggest[steps] = new_arr;
//             }
//             else if(!count){
//
//                 return [];
//             }
//
//             smallest_arr = new_arr;
//         }
//     }
//
//     if(suggest){
//
//         // needs to iterate in reverse direction
//
//         for(let x = suggest.length - 1, arr, len; x >= 0; x--){
//
//             arr = suggest[x];
//             len = arr && arr.length;
//
//             if(len){
//
//                 for(let y = 0, id; y < len; y++){
//
//                     id = arr[y];
//
//                     if(!check[id]){
//
//                         check[id] = 1;
//
//                         if(offset){
//
//                             offset--;
//                         }
//                         else{
//
//                             result[size++] = id;
//
//                             if(size === limit){
//
//                                 // fast path "end reached"
//
//                                 return result;
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
//
//     return result;
// }

/**
 * Implementation based on Object[key] provides better suggestions
 * capabilities and has less performance scaling issues on large indexes.
 *
 * @param arrays
 * @param limit
 * @param offset
 * @param {boolean|Array=} suggest
 * @returns {Array}
 */

export function intersect(arrays, limit, offset, suggest) {

    const length = arrays.length;
    let result = [];
    let check;
    let check_suggest;
    let size = 0;

    if(suggest){

        suggest = [];
    }

    // process terms in reversed order often has advantage for the fast path "end reached".
    // also a reversed order prioritize the order of words from a query.

    for(let x = length - 1; x >= 0; x--){

        const word_arr = arrays[x];
        const word_arr_len = word_arr.length;
        const check_new = create_object();

        let found = !check;

        // process relevance in forward order (direction is
        // important for adding IDs during the last round)

        for(let y = 0; y < word_arr_len; y++){

            const arr = word_arr[y];
            const arr_len = arr.length;

            if(arr_len){

                // loop through IDs

                for(let z = 0, check_idx, id; z < arr_len; z++){

                    id = arr[z];

                    if(check){

                        if(check[id]){

                            // check if in last round

                            if(!x){

                                if(offset){

                                    offset--;
                                }
                                else{

                                    result[size++] = id;

                                    if(size === limit){

                                        // fast path "end reached"

                                        return result;
                                    }
                                }
                            }

                            if(x || suggest){

                                check_new[id] = 1;
                            }

                            found = true;
                        }

                        if(suggest){

                            check_suggest[id] = (check_idx = check_suggest[id]) ? ++check_idx : check_idx = 1;

                            // do not adding IDs which are already included in the result (saves one loop)
                            // the first intersection match has the check index 2, so shift by -2

                            if(check_idx < length){

                                const tmp = suggest[check_idx - 2] || (suggest[check_idx - 2] = []);
                                tmp[tmp.length] = id;
                            }
                        }
                    }
                    else{

                        // pre-fill in first round

                        check_new[id] = 1;
                    }
                }
            }
        }

        if(suggest){

            // re-use the first pre-filled check for suggestions

            check || (check_suggest = check_new);
        }
        else if(!found){

            return [];
        }

        check = check_new;
    }

    if(suggest){

        // needs to iterate in reverse direction

        for(let x = suggest.length - 1, arr, len; x >= 0; x--){

            arr = suggest[x];
            len = arr.length;

            for(let y = 0, id; y < len; y++){

                id = arr[y];

                if(!check[id]){

                    if(offset){

                        offset--;
                    }
                    else{

                        result[size++] = id;

                        if(size === limit){

                            // fast path "end reached"

                            return result;
                        }
                    }

                    check[id] = 1;
                }
            }
        }
    }

    return result;
}

/**
 * @param mandatory
 * @param arrays
 * @returns {Array}
 */

export function intersect_union(mandatory, arrays) {

    const check = create_object();
    const union = create_object();
    const result = [];

    for(let x = 0; x < mandatory.length; x++){

        check[mandatory[x]] = 1;
    }

    for(let x = 0, arr; x <  arrays.length; x++){

        arr = arrays[x];

        for(let y = 0, id; y < arr.length; y++){

            id = arr[y];

            if(check[id]){

                if(!union[id]){

                    union[id] = 1;
                    result[result.length] = id;
                }
            }
        }
    }

    return result;
}