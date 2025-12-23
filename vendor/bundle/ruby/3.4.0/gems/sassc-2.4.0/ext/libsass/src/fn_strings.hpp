#ifndef SASS_FN_STRINGS_H
#define SASS_FN_STRINGS_H

#include "fn_utils.hpp"

namespace Sass {

  namespace Functions {

    extern Signature unquote_sig;
    extern Signature quote_sig;
    extern Signature str_length_sig;
    extern Signature str_insert_sig;
    extern Signature str_index_sig;
    extern Signature str_slice_sig;
    extern Signature to_upper_case_sig;
    extern Signature to_lower_case_sig;
    extern Signature length_sig;

    BUILT_IN(sass_unquote);
    BUILT_IN(sass_quote);
    BUILT_IN(str_length);
    BUILT_IN(str_insert);
    BUILT_IN(str_index);
    BUILT_IN(str_slice);
    BUILT_IN(to_upper_case);
    BUILT_IN(to_lower_case);
    BUILT_IN(length);

  }

}

#endif
