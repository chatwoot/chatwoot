#include "extconf.h"

// This file exports functions used to access private Ruby VM APIs and internals.
// To do this, it imports a few VM internal (private) headers.
//
// **Important Note**: Our medium/long-term plan is to stop relying on all private Ruby headers, and instead request and
// contribute upstream changes so that they become official public VM APIs.
//
// In the meanwhile, be very careful when changing things here :)

#ifdef RUBY_MJIT_HEADER
  // Pick up internal structures from the private Ruby MJIT header file
  #include RUBY_MJIT_HEADER
#else
  // The MJIT header was introduced on 2.6 and removed on 3.3; for other Rubies we rely on
  // the datadog-ruby_core_source gem to get access to private VM headers.

  // We can't do anything about warnings in VM headers, so we just use this technique to suppress them.
  // See https://nelkinda.com/blog/suppress-warnings-in-gcc-and-clang/#d11e364 for details.
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wunused-parameter"
  #pragma GCC diagnostic ignored "-Wattributes"
  #pragma GCC diagnostic ignored "-Wpragmas"
  #pragma GCC diagnostic ignored "-Wexpansion-to-defined"
    #include <vm_core.h>
  #pragma GCC diagnostic pop

  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wunused-parameter"
    #include <iseq.h>
  #pragma GCC diagnostic pop

  #include <ruby.h>

  #ifndef NO_RACTOR_HEADER_INCLUDE
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wunused-parameter"
      #include <ractor_core.h>
    #pragma GCC diagnostic pop
  #endif
#endif

// This file can't include datadog_ruby_common.h so we replicate this here
#ifdef __GNUC__
  #define DDTRACE_UNUSED  __attribute__((unused))
#else
  #define DDTRACE_UNUSED
#endif

#define PRIVATE_VM_API_ACCESS_SKIP_RUBY_INCLUDES
#include "private_vm_api_access.h"

// MRI has a similar rb_thread_ptr() function which we can't call it directly
// because Ruby does not expose the thread_data_type publicly.
// Instead, we have our own version of that function, and we lazily initialize the thread_data_type pointer
// from a known-correct object: the current thread.
//
// Note that beyond returning the rb_thread_struct*, rb_check_typeddata() raises an exception
// if the argument passed in is not actually a `Thread` instance.
static inline rb_thread_t *thread_struct_from_object(VALUE thread) {
  static const rb_data_type_t *thread_data_type = NULL;
  if (UNLIKELY(thread_data_type == NULL)) thread_data_type = RTYPEDDATA_TYPE(rb_thread_current());

  return (rb_thread_t *) rb_check_typeddata(thread, thread_data_type);
}

rb_nativethread_id_t pthread_id_for(VALUE thread) {
  // struct rb_native_thread was introduced in Ruby 3.2: https://github.com/ruby/ruby/pull/5836
  #ifndef NO_RB_NATIVE_THREAD
    struct rb_native_thread* native_thread = thread_struct_from_object(thread)->nt;
    // This can be NULL on Ruby 3.3 with MN threads (RUBY_MN_THREADS=1)
    if (native_thread == NULL) return 0;
    return native_thread->thread_id;
  #else
    return thread_struct_from_object(thread)->thread_id;
  #endif
}

// Queries if the current thread is the owner of the global VM lock.
//
// @ivoanjo: Ruby has a similarly-named `ruby_thread_has_gvl_p` but that API is insufficient for our needs because it can
// still return `true` even when a thread DOES NOT HAVE the global VM lock.
// In particular, looking at the implementation, that API assumes that if a thread is not in a "blocking region" then it
// will have the GVL which is probably true for the situations that API was designed to be called from BUT this assumption
// does not hold true when calling `ruby_thread_has_gvl_p` from a signal handler. (Because the thread may have lost the
// GVL due to a scheduler decision, not because it decided to block.)
// I have also submitted https://bugs.ruby-lang.org/issues/19172 to discuss this with upstream Ruby developers.
//
// Thus we need our own gvl-checking method which actually looks at the gvl structure to determine if it is the owner.
bool is_current_thread_holding_the_gvl(void) {
  current_gvl_owner owner = gvl_owner();
  return owner.valid && pthread_equal(pthread_self(), owner.owner);
}

#ifdef HAVE_RUBY_RACTOR_H
  static inline rb_ractor_t *ddtrace_get_ractor(void) {
    #ifndef USE_RACTOR_INTERNAL_APIS_DIRECTLY // Ruby >= 3.3
      return thread_struct_from_object(rb_thread_current())->ractor;
    #else
      return GET_RACTOR();
    #endif
  }
#endif

#ifndef NO_GVL_OWNER // Ruby < 2.6 doesn't have the owner/running field
  // NOTE: Reading the owner in this is a racy read, because we're not grabbing the lock that Ruby uses to protect it.
  //
  // While we could potentially grab this lock, I (@ivoanjo) think we actually don't need it because:
  // * In the case where a thread owns the GVL and calls `gvl_owner`, it will always see the correct value. That's
  //   because every thread sets itself as the owner when it grabs the GVL and unsets itself at the end.
  //   That means that `is_current_thread_holding_the_gvl` is always accurate.
  // * In a case where we observe a different thread, then this may change by the time we do something with this value
  //   anyway. So unless we want to prevent the Ruby scheduler from switching threads, we need to deal with races here.
  current_gvl_owner gvl_owner(void) {
    const rb_thread_t *current_owner =
      #ifndef NO_RB_THREAD_SCHED // Introduced in Ruby 3.2 as a replacement for struct rb_global_vm_lock_struct
        ddtrace_get_ractor()->threads.sched.running;
      #elif HAVE_RUBY_RACTOR_H
        ddtrace_get_ractor()->threads.gvl.owner;
      #else
        GET_VM()->gvl.owner;
      #endif

    if (current_owner == NULL) return (current_gvl_owner) {.valid = false};

    #ifndef NO_RB_NATIVE_THREAD
      struct rb_native_thread* current_owner_native_thread = current_owner->nt;

      // This can be NULL on Ruby 3.3 with MN threads (RUBY_MN_THREADS=1)
      if (current_owner_native_thread == NULL) return (current_gvl_owner) {.valid = false};

      return (current_gvl_owner) {.valid = true, .owner = current_owner_native_thread->thread_id};
    #else
      return (current_gvl_owner) {.valid = true, .owner = current_owner->thread_id};
    #endif
  }
#else
  current_gvl_owner gvl_owner(void) {
    rb_vm_t *vm = GET_VM();

    // BIG Issue: Ruby < 2.6 did not have the owner field. The really nice thing about the owner field is that it's
    // "atomic" -- when a thread sets it, it "declares" two things in a single step
    // * Declaration 1: Someone has the GVL
    // * Declaration 2: That someone is the specific thread
    //
    // Observation 1: On older versions of Ruby, this ownership concept is actually split. Specifically, `gvl.acquired`
    // is a boolean that represents declaration 1 above, and `vm->running_thread` (or `ruby_current_thread`/
    // `ruby_current_execution_context_ptr`) represents declaration 2.
    //
    // Observation 2: In addition, when a thread releases the GVL, it only sets `gvl.acquired` back to 0 **BUT CRUCIALLY
    // DOES NOT CHANGE THE OTHER global variables**.
    //
    // Observation 1+2 above lead to the following possible race:
    // * Thread A grabs the GVL (`gvl.acquired == 1`)
    // * Thread A sets `running_thread` (`gvl.acquired == 1` + `running_thread == Thread A`)
    // * Thread A releases the GVL (`gvl.acquired == 0` + `running_thread == Thread A`)
    // * Thread B grabs the GVL (`gvl.acquired == 1` + `running_thread == Thread A`)
    // * Thread A calls gvl_owner. Due to the current state (`gvl.acquired == 1` + `running_thread == Thread A`), this
    //   function returns an incorrect result.
    // * Thread B finally sets `running_thread` (`gvl.acquired == 1` + `running_thread == Thread B`)
    //
    // This is especially problematic because we use `gvl_owner` to implement `is_current_thread_holding_the_gvl` which
    // is called in a signal handler to decide "is it safe for me to call `rb_postponed_job_register_one` or not".
    // (See constraints in `collectors_cpu_and_wall_time_worker.c` comments for why).
    //
    // Thus an incorrect `is_current_thread_holding_the_gvl` result may lead to issues inside `rb_postponed_job_register_one`.
    //
    // For this reason we default to use the "no signals workaround" on Ruby 2.5 by default, and we print a
    // warning when customers force-enable it.
    bool gvl_acquired = vm->gvl.acquired != 0;
    rb_thread_t *current_owner = vm->running_thread;

    if (!gvl_acquired || current_owner == NULL) return (current_gvl_owner) {.valid = false};

    return (current_gvl_owner) {.valid = true, .owner = current_owner->thread_id};
  }
#endif // NO_GVL_OWNER

// Taken from upstream vm_core.h at commit d9cf0388599a3234b9f3c06ddd006cd59a58ab8b (November 2022, Ruby 3.2 trunk)
// Copyright (C) 2004-2007 Koichi Sasada
// to support tid_for (see below)
// Modifications: None
#if defined(__linux__) || defined(__FreeBSD__)
# define RB_THREAD_T_HAS_NATIVE_ID
#endif

uint64_t native_thread_id_for(VALUE thread) {
  // The tid is only available on Ruby >= 3.1 + Linux (and FreeBSD). It's the same as `gettid()` aka the task id as seen in /proc
  #if !defined(NO_THREAD_TID) && defined(RB_THREAD_T_HAS_NATIVE_ID)
    #ifndef NO_RB_NATIVE_THREAD
      struct rb_native_thread* native_thread = thread_struct_from_object(thread)->nt;
      if (native_thread == NULL) return 0;
      return native_thread->tid;
    #else
      return thread_struct_from_object(thread)->tid;
    #endif
  #else
    rb_nativethread_id_t pthread_id = pthread_id_for(thread);

    #ifdef __APPLE__
      uint64_t result;
      // On macOS, this gives us the same identifier that shows up in activity monitor
      int error = pthread_threadid_np(pthread_id, &result);
      if (error) rb_syserr_fail(error, "Unexpected failure in pthread_threadid_np");
      return result;
    #else
      // Fallback, when we have nothing better (e.g. on Ruby < 3.1 on Linux)
      // @ivoanjo: In the future we may want to explore some potential hacks to get the actual tid on linux
      // (e.g. https://stackoverflow.com/questions/558469/how-do-i-get-a-thread-id-from-an-arbitrary-pthread-t )
      return (uint64_t) pthread_id;
    #endif
  #endif
}

// This was renamed in Ruby 3.2
#if !defined(ccan_list_for_each) && defined(list_for_each)
  #define ccan_list_for_each list_for_each
#endif

// Tries to match rb_thread_list() but that method isn't accessible to extensions
void ddtrace_thread_list(VALUE result_array) {
  rb_thread_t *thread = NULL;

  // Ruby 3 Safety: Our implementation is inspired by `rb_ractor_thread_list` BUT that method wraps the operations below
  // with `RACTOR_LOCK` and `RACTOR_UNLOCK`.
  //
  // This initially made me believe that one MUST grab the ractor lock (which is different from the ractor-scoped Global
  // VM Lock) in able to iterate the `threads.set`. This turned out not to be the case: upon further study of the VM
  // codebase in 3.2-master, 3.1 and 3.0, there's quite a few places where `threads.set` is accessed without grabbing
  // the ractor lock: `ractor_mark` (ractor.c), `thgroup_list` (thread.c), `rb_check_deadlock` (thread.c), etc.
  //
  // I suspect the design in `rb_ractor_thread_list` may be done that way to perhaps in the future expose it to be
  // called from a different Ractor, but I'm not sure...
  #ifdef HAVE_RUBY_RACTOR_H
    rb_ractor_t *current_ractor = ddtrace_get_ractor();
    ccan_list_for_each(&current_ractor->threads.set, thread, lt_node) {
  #else
    rb_vm_t *vm = GET_VM();
    list_for_each(&vm->living_threads, thread, vmlt_node) {
  #endif
      switch (thread->status) {
        case THREAD_RUNNABLE:
        case THREAD_STOPPED:
        case THREAD_STOPPED_FOREVER:
          rb_ary_push(result_array, thread->self);
        default:
          break;
      }
    }
}

bool is_thread_alive(VALUE thread) {
  return thread_struct_from_object(thread)->status != THREAD_KILLED;
}

VALUE thread_name_for(VALUE thread) {
  return thread_struct_from_object(thread)->name;
}

// -----------------------------------------------------------------------------
// The sources below are modified versions of code extracted from the Ruby project.
// Each function is annotated with its origin, why we imported it, and the changes made.
//
// The Ruby project copyright and license follow:
// -----------------------------------------------------------------------------
// Copyright (C) 1993-2013 Yukihiro Matsumoto. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.

// Taken from upstream vm_core.h at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) 2004-2007 Koichi Sasada
// to support our custom rb_profile_frames (see below)
// Modifications: None
#define ISEQ_BODY(iseq) ((iseq)->body)

// Taken from upstream vm_backtrace.c at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) 1993-2012 Yukihiro Matsumoto
// to support our custom rb_profile_frames (see below)
// Modifications:
// * Support int first_lineno for Ruby 3.2.0+ (https://github.com/ruby/ruby/pull/6430)
// * Validate iseq and pos before calling `rb_iseq_line_no` as a safety measure (see comment below for details)
//
// `node_id` gets used depending on Ruby VM compilation settings (USE_ISEQ_NODE_ID being defined).
// To avoid getting false "unused argument" warnings in setups where it's not used, we need to do this weird dance
// with diagnostic stuff. See https://nelkinda.com/blog/suppress-warnings-in-gcc-and-clang/#d11e364 for details.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
static inline int
calc_pos(const rb_iseq_t *iseq, const VALUE *pc, int *lineno, int *node_id)
{
    VM_ASSERT(iseq);
    VM_ASSERT(ISEQ_BODY(iseq));
    VM_ASSERT(ISEQ_BODY(iseq)->iseq_encoded);
    VM_ASSERT(ISEQ_BODY(iseq)->iseq_size);
    if (! pc) {
        if (ISEQ_BODY(iseq)->type == ISEQ_TYPE_TOP) {
            VM_ASSERT(! ISEQ_BODY(iseq)->local_table);
            VM_ASSERT(! ISEQ_BODY(iseq)->local_table_size);
            return 0;
        }
        # ifndef NO_INT_FIRST_LINENO // Ruby 3.2+
          if (lineno) *lineno = ISEQ_BODY(iseq)->location.first_lineno;
        # else
          if (lineno) *lineno = FIX2INT(ISEQ_BODY(iseq)->location.first_lineno);
        #endif
#ifdef USE_ISEQ_NODE_ID
        if (node_id) *node_id = -1;
#endif
        return 1;
    }
    else {
        ptrdiff_t n = pc - ISEQ_BODY(iseq)->iseq_encoded;
        VM_ASSERT(n <= ISEQ_BODY(iseq)->iseq_size);
        VM_ASSERT(n >= 0);
        ASSUME(n >= 0);
        size_t pos = n; /* no overflow */
        if (LIKELY(pos)) {
            /* use pos-1 because PC points next instruction at the beginning of instruction */
            pos--;
        }
#if VMDEBUG && defined(HAVE_BUILTIN___BUILTIN_TRAP)
        else {
            /* SDR() is not possible; that causes infinite loop. */
            rb_print_backtrace();
            __builtin_trap();
        }
#endif

        // In PROF-11475 we spotted a crash when calling `rb_iseq_line_no` from this method.
        // We were only able to reproduce this issue on Ruby 2.6 and 2.7, not 2.5 or the 3.x series (tried 3.0, 3.2 and 3.4).
        // Note that going out of bounds doesn't crash every time, as usual with C we may just read garbage or get lucky.
        //
        // For those problematic Rubies, we observed that when we try to take a sample in the middle of processing the
        // VM `LEAVE` instruction, the value of `n` can violate the documented assumptions above and be
        // `n > ISEQ_BODY(iseq)->iseq_size)`.
        //
        // To work around this and any other potential issues, we validate here that the bytecode position is sane.
        if (RB_UNLIKELY(n < 0 || n > ISEQ_BODY(iseq)->iseq_size)) return 0;

        if (lineno) *lineno = rb_iseq_line_no(iseq, pos);
#ifdef USE_ISEQ_NODE_ID
        if (node_id) *node_id = rb_iseq_node_id(iseq, pos);
#endif
        return 1;
    }
}
#pragma GCC diagnostic pop

// Taken from upstream vm_backtrace.c at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) 1993-2012 Yukihiro Matsumoto
// to support our custom rb_profile_frames (see below)
// Modifications: None
static inline int
calc_lineno(const rb_iseq_t *iseq, const VALUE *pc)
{
    int lineno;
    if (calc_pos(iseq, pc, &lineno, NULL)) return lineno;
    return 0;
}

// Taken from upstream vm_backtrace.c at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) 1993-2012 Yukihiro Matsumoto
// Modifications:
// * Renamed rb_profile_frames => ddtrace_rb_profile_frames
// * Add thread argument (this is now upstream, actually!)
// * Add frame_flags.is_ruby_frame argument
// * Removed `if (lines)` tests -- require/assume that like `buff`, `lines` is always specified
// * Skip dummy frame that shows up in main thread
// * Add `end_cfp == NULL` and `end_cfp <= cfp` safety checks. These are used in a bunch of places in
//   `vm_backtrace.c` (`backtrace_each`, `backtrace_size`, `rb_ec_partial_backtrace_object`) but are conspicuously
//   absent from `rb_profile_frames`. Oversight?
// * Skip frames where `cfp->iseq && !cfp->pc`. These seem to be internal and are skipped by `backtrace_each` in
//   `vm_backtrace.c`.
// * Check thread status and do not sample if thread has been killed.
// * Match Ruby reference stack trace APIs that use the iseq instead of the callable method entry to get information
//   for iseqs created from calls to `eval` and `instance_eval`. This makes it so that `rb_profile_frame_path` on
//   the `VALUE` returned by rb_profile_frames returns `(eval)` instead of the path of the file where the `eval`
//   was called from.
// * Imported fix from https://github.com/ruby/ruby/pull/7116 to avoid sampling threads that are still being created
// * Imported fix from https://github.com/ruby/ruby/pull/8415 to avoid potential crash when using YJIT.
// * Add frame_flags.same_frame and logic to skip redoing work if the buffer already contains the same data we're collecting
// * Skipped use of rb_callable_method_entry_t (cme) for Ruby frames as it doesn't impact us.
// * Imported fix from https://github.com/ruby/ruby/pull/8280 to keep us closer to upstream
// * Added potential fix for https://github.com/ruby/ruby/pull/13643 (this one is a just-in-case, unclear if it happens
//   for ddtrace)
// * Reversed order of iteration to better enable caching
//
// What is rb_profile_frames?
// `rb_profile_frames` is a Ruby VM debug API added for use by profilers for sampling the stack trace of a Ruby thread.
// Its main other user is the stackprof profiler: https://github.com/tmm1/stackprof .
//
// Why do we need a custom version of rb_profile_frames?
//
// There are a few reasons:
// 1. To backport improved behavior to older Rubies. Prior to Ruby 3.0 (https://github.com/ruby/ruby/pull/3299),
//    rb_profile_frames skipped CFUNC frames, aka frames that are implemented with native code, and thus the resulting
//    stacks were quite incomplete as a big part of the Ruby standard library is implemented with native code.
//
// 2. To extend this function to work with any thread. The upstream rb_profile_frames function only targets the current
//    thread, and to support wall-clock profiling we require sampling other threads. This is only safe because of the
//    Global VM Lock. (We don't yet support sampling Ractors beyond the main one; we'll need to find a way to do it
//    safely first.)
//
// 3. To get more information out of the Ruby VM. The Ruby VM has a lot more information than is exposed through
//    rb_profile_frames, and by making our own copy of this function we can extract more of this information.
//    See for backtracie gem (https://github.com/ivoanjo/backtracie) for an exploration of what can potentially be done.
//
// 4. Because we haven't yet submitted patches to upstream Ruby. As with any changes on the `private_vm_api_access.c`,
//    our medium/long-term plan is to contribute upstream changes and make it so that we don't need any of this
//    on modern Rubies.
//
// 5. To make rb_profile_frames behave more like the Ruby-level reference stack trace APIs (`Thread#backtrace_locations`
//    and friends). We've found quite a few situations where the data from rb_profile_frames and the reference APIs
//    disagree, and quite a few of them seem oversights/bugs (speculation from my part) rather than deliberate
//    decisions.
int ddtrace_rb_profile_frames(VALUE thread, int start, int limit, frame_info *stack_buffer) {
    int i;
    // Modified from upstream: Instead of using `GET_EC` to collect info from the current thread,
    // support sampling any thread (including the current) passed as an argument
    rb_thread_t *th = thread_struct_from_object(thread);
    const rb_execution_context_t *ec = th->ec;

    // As of this writing, we don't support profiling with MN enabled, and this only happens in that mode, but as we
    // probably want to experiment with it in the future, I've decided to import https://github.com/ruby/ruby/pull/9310
    // here.
    if (ec == NULL) return 0;

    // I suspect this won't happen for ddtrace, but just-in-case we've imported a potential fix for
    // https://github.com/ruby/ruby/pull/13643 by assuming that these can be NULL/zero with the cfp being non-NULL yet.
    if (ec->vm_stack == NULL || ec->vm_stack_size == 0) return 0;

    const rb_control_frame_t *cfp = ec->cfp, *end_cfp = RUBY_VM_END_CONTROL_FRAME(ec);
    #ifndef NO_JIT_RETURN
      const rb_control_frame_t *top = cfp;
    #endif
    const rb_callable_method_entry_t *cme;

    // Avoid sampling dead threads
    if (th->status == THREAD_KILLED) return 0;

    // `vm_backtrace.c` includes this check in several methods. This happens on newly-created threads, and may
    // also (not entirely sure) happen on dead threads
    if (end_cfp == NULL) return PLACEHOLDER_STACK_IN_NATIVE_CODE;

    // This should not happen for ddtrace (it can only happen when a thread is still being created), but I've imported
    // it from https://github.com/ruby/ruby/pull/7116 in a "just in case" kind of mindset.
    if (cfp == NULL) return 0;

    // Fix: Skip dummy frame that shows up in main thread.
    //
    // According to a comment in `backtrace_each` (`vm_backtrace.c`), there's two dummy frames that we should ignore
    // at the base of every thread's stack.
    // (see https://github.com/ruby/ruby/blob/4bd38e8120f2fdfdd47a34211720e048502377f1/vm_backtrace.c#L890-L914 )
    //
    // One is being pointed to by `RUBY_VM_END_CONTROL_FRAME(ec)`, and so we need to advance to the next one, and
    // reaching it will be used as a condition to break out of the loop below.
    //
    // Note that in `backtrace_each` there's two calls to `RUBY_VM_NEXT_CONTROL_FRAME`, but the loop bounds there
    // are computed in a different way, so the two calls really are equivalent to one here.
    end_cfp = RUBY_VM_NEXT_CONTROL_FRAME(end_cfp);

    // See comment on `record_placeholder_stack_in_native_code` for a full explanation of what this means (and why we don't just return 0)
    if (end_cfp <= cfp) return PLACEHOLDER_STACK_IN_NATIVE_CODE;

    // This is the position just after the top of the stack -- e.g. where a new frame pushed on the stack would end up.
    const rb_control_frame_t *top_sentinel = RUBY_VM_NEXT_CONTROL_FRAME(cfp);

    // We iterate the stack from bottom (beginning of thread) to the top (currently-active frame). This is different
    // from upstream rb_profile_frames, but actually matches what `backtrace_each` does (yes, different Ruby VM APIs
    // iterate in different directions).
    // We do this to better take advantage of the `same_frame` caching mechanism: By starting from the bottom of the
    // stack towards the top, we can usually keep most of the stack intact when the code is only going up and down
    // a few methods at the top. Before this change, the cache was really only useful if between samples the app had
    // not moved from the current stack, as adding or removing one frame would invalidate the existing cache (because
    // every position would shift).
    cfp = RUBY_VM_NEXT_CONTROL_FRAME(end_cfp);

    for (i=0; i<limit && cfp != top_sentinel; cfp = RUBY_VM_NEXT_CONTROL_FRAME(cfp)) {
        if (cfp->iseq && !cfp->pc) {
          // Fix: Do nothing -- this frame should not be used
          //
          // rb_profile_frames does not do this check, but `backtrace_each` (`vm_backtrace.c`) does. This frame is not
          // exposed by the Ruby backtrace APIs and for now we want to match its behavior 1:1
        }
        else if (VM_FRAME_RUBYFRAME_P(cfp)) {
            if (start > 0) {
                start--;
                continue;
            }

            stack_buffer[i].same_frame =
              stack_buffer[i].is_ruby_frame &&
              stack_buffer[i].as.ruby_frame.iseq == (VALUE) cfp->iseq &&
              stack_buffer[i].as.ruby_frame.caching_pc == cfp->pc;

            if (stack_buffer[i].same_frame) { // Nothing to do, buffer already contains this frame
              i++;
              continue;
            }

            // dd-trace-rb NOTE:
            // Upstream Ruby has code here to retrieve the rb_callable_method_entry_t (cme) and in some cases to use it
            // instead of the iseq.
            // In practice, they are usually the same; the difference is that when you have e.g. block, one gets you a
            // reference to the block, and the other to the method containing the block.
            // This would be important if we used `rb_profile_frame_label` and wanted the "block in foo" label instead
            // of just "foo". But we're currently using `rb_profile_frame_base_label` which I believe is always the same
            // between the rb_callable_method_entry_t and the iseq. Thus, to simplify a bit our logic and reduce a bit
            // the overhead, we always use the iseq here.
            //
            // @ivoanjo: I've left the upstream Ruby code commented out below for reference, so it's more obvious that
            // we're diverging, and we can easily compare and experiment with the upstream version in the future.
            //
            // cme = rb_vm_frame_method_entry(cfp);

            // if (cme && cme->def->type == VM_METHOD_TYPE_ISEQ &&
            //   // Fix: Do not use callable method entry when iseq is for an eval.
            //   // TL;DR: This fix is needed for us to match the Ruby reference API information in the
            //   // "when sampling an eval/instance eval inside an object" spec.
            //   cfp->iseq->body->type != ISEQ_TYPE_EVAL) {
            //     buff[i] = (VALUE)cme;
            // }
            // else {
            stack_buffer[i].as.ruby_frame.iseq = (VALUE)cfp->iseq;
            stack_buffer[i].as.ruby_frame.caching_pc = (void *) cfp->pc;
            // }

            // The topmost frame may not have an updated PC because the JIT
            // may not have set one.  The JIT compiler will update the PC
            // before entering a new function (so that `caller` will work),
            // so only the topmost frame could possibly have an out of date PC
            #ifndef NO_JIT_RETURN
              if (cfp == top && cfp->jit_return) {
                stack_buffer[i].as.ruby_frame.line = 0;
              } else {
                stack_buffer[i].as.ruby_frame.line = calc_lineno(cfp->iseq, cfp->pc);
              }
            #else // Ruby < 3.1
              stack_buffer[i].as.ruby_frame.line = calc_lineno(cfp->iseq, cfp->pc);
            #endif

            stack_buffer[i].is_ruby_frame = true;
            i++;
        }
        else {
            cme = rb_vm_frame_method_entry(cfp);
            if (cme && cme->def->type == VM_METHOD_TYPE_CFUNC) {
                if (start > 0) {
                    start--;
                    continue;
                }

                stack_buffer[i].same_frame =
                  !stack_buffer[i].is_ruby_frame &&
                  stack_buffer[i].as.native_frame.caching_cme == (VALUE) cme;

                if (stack_buffer[i].same_frame) { // Nothing to do, buffer already contains this frame
                  i++;
                  continue;
                }

                stack_buffer[i].as.native_frame.caching_cme = (VALUE)cme;
                stack_buffer[i].as.native_frame.method_id = cme->def->original_id;
                stack_buffer[i].as.native_frame.function = cme->def->body.cfunc.func;
                stack_buffer[i].is_ruby_frame = false;
                i++;
            }
        }
    }

    return i;
}

// Support code for older Rubies that cannot use the MJIT header
#ifndef RUBY_MJIT_HEADER

#define MJIT_STATIC // No-op on older Rubies

// Taken from upstream include/ruby/backward/2/bool.h at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) Ruby developers <ruby-core@ruby-lang.org>
// to support our custom rb_profile_frames (see above)
// Modifications: None
#ifndef FALSE
# define FALSE false
#elif FALSE
# error FALSE must be false
#endif

#ifndef TRUE
# define TRUE true
#elif ! TRUE
# error TRUE must be true
#endif

// Taken from upstream vm_insnhelper.c at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) 2007 Koichi Sasada
// to support our custom rb_profile_frames (see above)
// Modifications:
// * Removed debug checks (they were ifdef'd out anyway)
static rb_callable_method_entry_t *
check_method_entry(VALUE obj, int can_be_svar)
{
    if (obj == Qfalse) return NULL;

    switch (imemo_type(obj)) {
      case imemo_ment:
        return (rb_callable_method_entry_t *)obj;
      case imemo_cref:
        return NULL;
      case imemo_svar:
        if (can_be_svar) {
            return check_method_entry(((struct vm_svar *)obj)->cref_or_me, FALSE);
        }
        // fallthrough
      default:
        return NULL;
    }
}

// Taken from upstream vm_insnhelper.c at commit 5f10bd634fb6ae8f74a4ea730176233b0ca96954 (March 2022, Ruby 3.2 trunk)
// Copyright (C) 2007 Koichi Sasada
// to support our custom rb_profile_frames (see above)
//
// While older Rubies may have this function, the symbol is not exported which leads to dynamic loader issues, e.g.
// `dyld: lazy symbol binding failed: Symbol not found: _rb_vm_frame_method_entry`.
//
// Modifications: None
MJIT_STATIC const rb_callable_method_entry_t *
rb_vm_frame_method_entry(const rb_control_frame_t *cfp)
{
    const VALUE *ep = cfp->ep;
    rb_callable_method_entry_t *me;

    while (!VM_ENV_LOCAL_P(ep)) {
        if ((me = check_method_entry(ep[VM_ENV_DATA_INDEX_ME_CREF], FALSE)) != NULL) return me;
        ep = VM_ENV_PREV_EP(ep);
    }

    return check_method_entry(ep[VM_ENV_DATA_INDEX_ME_CREF], TRUE);
}
#endif // RUBY_MJIT_HEADER

#ifndef NO_RACTORS
  // This API and definition are exported as a public symbol by the VM BUT the function header is not defined in any public header, so we
  // repeat it here to be able to use in our code.
  #ifndef USE_RACTOR_INTERNAL_APIS_DIRECTLY
    // Disable fast path for detecting multiple Ractors. Unfortunately this symbol is no longer visible on modern Ruby
    // versions, so we need to do a bit more work.
    struct rb_ractor_struct *ruby_single_main_ractor = NULL;

    // Alternative implementation of rb_ractor_main_p_ that avoids relying on non-public symbols
    bool rb_ractor_main_p_(void) {
      // We need to get the main ractor in a bit of a roundabout way, since Ruby >= 3.3 hid `GET_VM()`
      return ddtrace_get_ractor() == thread_struct_from_object(rb_thread_current())->vm->ractor.main_ractor;
    }
  #else
    // Directly access Ruby internal fast path for detecting multiple Ractors.
    extern struct rb_ractor_struct *ruby_single_main_ractor;

    // Ruby 3.0 to 3.2 directly expose this symbol, we just need to tell the compiler it exists.
    bool rb_ractor_main_p_(void);
  #endif

  // Taken from upstream ractor_core.h at commit d9cf0388599a3234b9f3c06ddd006cd59a58ab8b (November 2022, Ruby 3.2 trunk)
  // to allow us to ensure that we're always operating on the main ractor (if Ruby has ractors)
  // Modifications:
  // * None
  bool ddtrace_rb_ractor_main_p(void)
  {
      if (ruby_single_main_ractor) {
          return true;
      }
      else {
          return rb_ractor_main_p_();
      }
  }
#else
  // Simplify callers on older Rubies, instead of having them probe if the VM supports Ractors we just tell them that yes
  // they're always on the main Ractor
  bool ddtrace_rb_ractor_main_p(void) { return true; }
#endif // NO_RACTORS

// This is a tweaked and inlined version of
// threadptr_invoke_proc_location + rb_proc_location + iseq_location .
//
// It's useful to have here because not all of the methods above are accessible to extensions + to avoid the
// array allocation that iseq_location did to contain its return value.
static const rb_iseq_t *maybe_thread_invoke_proc_iseq(VALUE thread_value) {
  rb_thread_t *thread = thread_struct_from_object(thread_value);

  #ifndef NO_THREAD_INVOKE_ARG // Ruby 2.6+
    if (thread->invoke_type != thread_invoke_type_proc) return NULL;

    VALUE proc = thread->invoke_arg.proc.proc;
  #else
    if (thread->first_func || !thread->first_proc) return NULL;

    VALUE proc = thread->first_proc;
  #endif

  const rb_iseq_t *iseq = rb_proc_get_iseq(proc, 0);
  if (iseq == NULL) return NULL;

  rb_iseq_check(iseq);
  return iseq;
}

VALUE invoke_location_for(VALUE thread, int *line_location) {
  const rb_iseq_t *iseq = maybe_thread_invoke_proc_iseq(thread);

  if (iseq == NULL) return Qnil;

  *line_location = NUM2INT(rb_iseq_first_lineno(iseq));
  return rb_iseq_path(iseq);
}

void self_test_mn_enabled(void) {
  #ifdef NO_MN_THREADS_AVAILABLE
    return;
  #else
    if (ddtrace_get_ractor()->threads.sched.enable_mn_threads == true) {
      rb_raise(rb_eRuntimeError, "Ruby VM is running with RUBY_MN_THREADS=1. This is not yet supported");
    }
  #endif
}

// Taken from upstream imemo.h at commit 6ebcf25de2859b5b6402b7e8b181066c32d0e0bf (November 2023, master branch)
// (See the Ruby project copyright and license above)
// to enable calling rb_imemo_name
//
// Modifications:
// * Added IMEMO_MASK define
// * Changed return type to int to avoid having to define `enum imemo_type`
static inline int ddtrace_imemo_type(VALUE imemo) {
  // This mask is the same between Ruby 2.5 and 3.3-preview3. Furthermore, the intention of this method is to be used
  // to call `rb_imemo_name` which correctly handles invalid numbers so even if the mask changes in the future, at most
  // we'll get incorrect results (and never a VM crash)
  #define IMEMO_MASK   0x0f
  return (RBASIC(imemo)->flags >> FL_USHIFT) & IMEMO_MASK;
}

// Safety: This function assumes the object passed in is of the imemo type. But in the worst case, you'll just get
// a string that doesn't make any sense.
#ifndef NO_IMEMO_NAME
  const char *imemo_kind(VALUE imemo) {
    return rb_imemo_name(ddtrace_imemo_type(imemo));
  }
#else
  const char *imemo_kind(__attribute__((unused)) VALUE imemo) {
    return NULL;
  }
#endif

// This is used to workaround a VM bug. See "handle_sampling_signal" in "collectors_cpu_and_wall_time_worker" for details.
#ifdef NO_POSTPONED_TRIGGER
  void *objspace_ptr_for_gc_finalize_deferred_workaround(void) {
    return GET_VM()->objspace;
  }
#endif

#ifdef USE_GVL_PROFILING_3_2_WORKAROUNDS // Ruby 3.2
  #include "gvl_profiling_helper.h"

  gvl_profiling_thread thread_from_thread_object(VALUE thread) {
    return (gvl_profiling_thread) {.thread = thread_struct_from_object(thread)};
  }

  // Hack: In Ruby 3.3+ we attach gvl profiling state to Ruby threads using the
  // rb_internal_thread_specific_* APIs. These APIs did not exist on Ruby 3.2. On Ruby 3.2 we instead store the
  // needed data inside the `rb_thread_t` structure, specifically in `stat_insn_usage` as a Ruby FIXNUM.
  //
  // Why `stat_insn_usage`? We needed some per-thread storage, and while looking at the Ruby VM sources I noticed
  // that `stat_insn_usage` has been in `rb_thread_t` for a long time, but is not used anywhere in the VM
  // code. There's a comment attached to it "/* statistics data for profiler */" but other than marking this
  // field for GC, I could not find any place in the VM commit history or on GitHub where this has ever been used.
  //
  // Thus, since this hack is only for 3.2, which presumably will never see this field either removed or used
  // during its remaining maintenance release period we... kinda take it for our own usage. It's ugly, I know...
  intptr_t gvl_profiling_state_get(gvl_profiling_thread thread) {
    if (thread.thread == NULL) return 0;

    VALUE current_value = ((rb_thread_t *)thread.thread)->stat_insn_usage;
    intptr_t result = current_value == Qnil ? 0 : FIX2LONG(current_value);
    return result;
  }

  void gvl_profiling_state_set(gvl_profiling_thread thread, intptr_t value) {
    if (thread.thread == NULL) return;
    ((rb_thread_t *)thread.thread)->stat_insn_usage = LONG2FIX(value);
  }

  // Because Ruby 3.2 does not give us the current thread when calling the RUBY_INTERNAL_THREAD_EVENT_READY and
  // RUBY_INTERNAL_THREAD_EVENT_RESUMED APIs, we need to figure out this info ourselves.
  //
  // Specifically, this method was created to be called from a RUBY_INTERNAL_THREAD_EVENT_RESUMED callback --
  // when it's triggered, we know the thread the code gets executed on is holding the GVL, so we use this
  // opportunity to initialize our thread-local value.
  gvl_profiling_thread gvl_profiling_state_maybe_initialize(void) {
    gvl_profiling_thread current_thread = gvl_waiting_tls;

    if (current_thread.thread == NULL) {
      // threads.sched.running is the thread currently holding the GVL, which when this gets executed is the
      // current thread!
      current_thread = (gvl_profiling_thread) {.thread = (void *) rb_current_ractor()->threads.sched.running};
      gvl_waiting_tls = current_thread;
    }

    return current_thread;
  }
#endif

// Is the VM smack in the middle of raising an exception?
bool is_raised_flag_set(VALUE thread) { return thread_struct_from_object(thread)->ec->raised_flag > 0; }

#ifndef NO_CURRENT_FIBER_FOR
  // The following three declarations are all
  // taken from upstream cont.c at commit d97884a58be32e829fd03a80cd521f4733d65c79 (February 2025, master branch)
  // (See the Ruby project copyright and license above)
  // to enable building `current_fiber_for`.
  //
  // We needed to copy them because they aren't otherwise exposed in any VM APIs or headers.
  // @ivoanjo: I manually checked the Ruby 3.1, 3.2, 3.3 and 3.4 branches + master, and the parts we care about in these
  // structures have not changed in many years (in fact, last change I spotted was for 2.7).
  enum context_type {
      CONTINUATION_CONTEXT = 0,
      FIBER_CONTEXT = 1
  };

  typedef struct rb_context_struct { // This declaration is incomplete -- only contains up to `self` which is the part we care about
      enum context_type type;
      int argc;
      int kw_splat;
      VALUE self;
  } rb_context_t;

  struct rb_fiber_struct { // This declaration is incomplete -- only contains the first entry which is the part we care about
    rb_context_t cont;
  };

  VALUE current_fiber_for(VALUE thread) {
    VALUE self = thread_struct_from_object(thread)->ec->fiber_ptr->cont.self;
    return self == 0 ? Qnil : self;
  }

  void self_test_current_fiber_for(void) {
    VALUE expected_current_fiber = current_fiber_for(rb_thread_current());
    VALUE actual_current_fiber = rb_fiber_current();

    if (expected_current_fiber == Qnil) {
      // On purpose above we tried reading before calling `rb_fiber_current()` so the fiber may have not existed yet.
      // But now it should be there.
      expected_current_fiber = current_fiber_for(rb_thread_current());
    }

    if (expected_current_fiber != actual_current_fiber) rb_raise(rb_eRuntimeError, "current_fiber_for() self-test failed");
  }
#else
  NORETURN(VALUE current_fiber_for(DDTRACE_UNUSED VALUE thread));

  VALUE current_fiber_for(DDTRACE_UNUSED VALUE thread) { rb_raise(rb_eRuntimeError, "Not implemented for Ruby < 3.1"); }
  void self_test_current_fiber_for(void) { } // Nothing to do
#endif
