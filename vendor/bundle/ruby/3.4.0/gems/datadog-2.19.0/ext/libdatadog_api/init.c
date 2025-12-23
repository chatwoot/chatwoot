#include <ruby.h>

#include "datadog_ruby_common.h"
#include "crashtracker.h"
#include "process_discovery.h"
#include "library_config.h"

void DDTRACE_EXPORT Init_libdatadog_api(void) {
  VALUE datadog_module = rb_define_module("Datadog");
  VALUE core_module = rb_define_module_under(datadog_module, "Core");

  crashtracker_init(core_module);
  process_discovery_init(core_module);
  library_config_init(core_module);
}
