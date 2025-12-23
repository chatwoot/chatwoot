#ifndef SASS_FN_MISCS_H
#define SASS_FN_MISCS_H

#include "fn_utils.hpp"

namespace Sass {

  namespace Functions {

    extern Signature type_of_sig;
    extern Signature variable_exists_sig;
    extern Signature global_variable_exists_sig;
    extern Signature function_exists_sig;
    extern Signature mixin_exists_sig;
    extern Signature feature_exists_sig;
    extern Signature call_sig;
    extern Signature not_sig;
    extern Signature if_sig;
    extern Signature set_nth_sig;
    extern Signature content_exists_sig;
    extern Signature get_function_sig;

    BUILT_IN(type_of);
    BUILT_IN(variable_exists);
    BUILT_IN(global_variable_exists);
    BUILT_IN(function_exists);
    BUILT_IN(mixin_exists);
    BUILT_IN(feature_exists);
    BUILT_IN(call);
    BUILT_IN(sass_not);
    BUILT_IN(sass_if);
    BUILT_IN(set_nth);
    BUILT_IN(content_exists);
    BUILT_IN(get_function);

  }

}

#endif
