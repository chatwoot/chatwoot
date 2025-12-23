// VERSION = "x.y.z"
#include <ruby.h>
#ifdef _WIN32
#define RUSAGE_SELF 0
#define RUSAGE_CHILDREN 0
#else
#include <sys/resource.h>
#endif

VALUE v_usage_struct;

static VALUE do_rusage_get(int who){
#ifdef _WIN32
  return rb_struct_new(v_usage_struct,
      rb_float_new(0),
      rb_float_new(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0),
      LONG2NUM(0)
   );
#else // _WIN32
  struct rusage r;
  int ret;

  ret = getrusage(who, &r);
  if(ret == -1)
    rb_sys_fail("getrusage");

  return rb_struct_new(v_usage_struct,
      rb_float_new((double)r.ru_utime.tv_sec+(double)r.ru_utime.tv_usec/1e6),
      rb_float_new((double)r.ru_stime.tv_sec+(double)r.ru_stime.tv_usec/1e6),
      LONG2NUM(r.ru_maxrss),
      LONG2NUM(r.ru_ixrss),
      LONG2NUM(r.ru_idrss),
      LONG2NUM(r.ru_isrss),
      LONG2NUM(r.ru_minflt),
      LONG2NUM(r.ru_majflt),
      LONG2NUM(r.ru_nswap),
      LONG2NUM(r.ru_inblock),
      LONG2NUM(r.ru_oublock),
      LONG2NUM(r.ru_msgsnd),
      LONG2NUM(r.ru_msgrcv),
      LONG2NUM(r.ru_nsignals),
      LONG2NUM(r.ru_nvcsw),
      LONG2NUM(r.ru_nivcsw)
   );
#endif // _WIN32
}

static VALUE rusage_get(int argc, VALUE* argv, VALUE mod){
  return do_rusage_get(RUSAGE_SELF);
}

static VALUE crusage_get(int argc, VALUE* argv, VALUE mod){
  return do_rusage_get(RUSAGE_CHILDREN);
}

void Init_rusage(){
  v_usage_struct =
     rb_struct_define("RUsage","utime","stime","maxrss","ixrss","idrss",
        "isrss","minflt","majflt","nswap","inblock","oublock","msgsnd",
        "msgrcv","nsignals","nvcsw","nivcsw",NULL
     );

  rb_define_module_function(rb_mProcess, "rusage", rusage_get, -1);
  rb_define_module_function(rb_mProcess, "crusage", crusage_get, -1);
}
