#pragma once

#include <ruby.h>
#include <datadog/profiling.h>

VALUE from_ddog_prof_EncodedProfile(ddog_prof_EncodedProfile profile);
VALUE enforce_encoded_profile_instance(VALUE object);
ddog_prof_EncodedProfile *to_ddog_prof_EncodedProfile(VALUE object);
