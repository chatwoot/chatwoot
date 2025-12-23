#ifndef SASS_FN_MAPS_H
#define SASS_FN_MAPS_H

#include "fn_utils.hpp"

namespace Sass {

  namespace Functions {

    #define ARGM(argname, argtype) get_arg_m(argname, env, sig, pstate, traces)

    extern Signature map_get_sig;
    extern Signature map_merge_sig;
    extern Signature map_remove_sig;
    extern Signature map_keys_sig;
    extern Signature map_values_sig;
    extern Signature map_has_key_sig;

    BUILT_IN(map_get);
    BUILT_IN(map_merge);
    BUILT_IN(map_remove);
    BUILT_IN(map_keys);
    BUILT_IN(map_values);
    BUILT_IN(map_has_key);

  }

}

#endif
