// Copyright 2021-Present Datadog, Inc. https://www.datadoghq.com/
// SPDX-License-Identifier: Apache-2.0


#ifndef DDOG_CRASHTRACKER_H
#define DDOG_CRASHTRACKER_H

#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "common.h"

#if defined(_WIN32) && defined(_CRASHTRACKING_COLLECTOR)
#include <werapi.h>
#include <windows.h>
#endif



typedef enum  ddog_crasht_CrashInfoBuilder_NewResult_Tag {
  DDOG_CRASHT_CRASH_INFO_BUILDER_NEW_RESULT_OK,
  DDOG_CRASHT_CRASH_INFO_BUILDER_NEW_RESULT_ERR,
}  ddog_crasht_CrashInfoBuilder_NewResult_Tag;

typedef struct  ddog_crasht_CrashInfoBuilder_NewResult {
   ddog_crasht_CrashInfoBuilder_NewResult_Tag tag;
  union {
    struct {
      struct ddog_crasht_Handle_CrashInfoBuilder ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
}  ddog_crasht_CrashInfoBuilder_NewResult;

typedef enum  ddog_crasht_StackTrace_NewResult_Tag {
  DDOG_CRASHT_STACK_TRACE_NEW_RESULT_OK,
  DDOG_CRASHT_STACK_TRACE_NEW_RESULT_ERR,
}  ddog_crasht_StackTrace_NewResult_Tag;

typedef struct  ddog_crasht_StackTrace_NewResult {
   ddog_crasht_StackTrace_NewResult_Tag tag;
  union {
    struct {
      struct ddog_crasht_Handle_StackTrace ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
}  ddog_crasht_StackTrace_NewResult;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * Disables the crashtracker.
 * Note that this does not restore the old signal handlers, but rather turns crash-tracking into a
 * no-op, and then chains the old handlers.  This means that handlers registered after the
 * crashtracker will continue to work as expected.
 *
 * # Preconditions
 *   None
 * # Safety
 *   None
 * # Atomicity
 *   This function is atomic and idempotent.  Calling it multiple times is allowed.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_disable(void);

/**
 * Enables the crashtracker, if it had been previously disabled.
 * If crashtracking has not been initialized, this function will have no effect.
 *
 * # Preconditions
 *   None
 * # Safety
 *   None
 * # Atomicity
 *   This function is atomic and idempotent.  Calling it multiple times is allowed.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_enable(void);

/**
 * Reinitialize the crash-tracking infrastructure after a fork.
 * This should be one of the first things done after a fork, to minimize the
 * chance that a crash occurs between the fork, and this call.
 * In particular, reset the counters that track the profiler state machine.
 * NOTE: An alternative design would be to have a 1:many sidecar listening on a
 * socket instead of 1:1 receiver listening on a pipe, but the only real
 * advantage would be to have fewer processes in `ps -a`.
 *
 * # Preconditions
 *   This function assumes that the crash-tracker has previously been
 *   initialized.
 * # Safety
 *   Crash-tracking functions are not reentrant.
 *   No other crash-handler functions should be called concurrently.
 * # Atomicity
 *   This function is not atomic. A crash during its execution may lead to
 *   unexpected crash-handling behaviour.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_update_on_fork(struct ddog_crasht_Config config,
                                                  struct ddog_crasht_ReceiverConfig receiver_config,
                                                  struct ddog_crasht_Metadata metadata);

/**
 * Initialize the crash-tracking infrastructure.
 *
 * # Preconditions
 *   None.
 * # Safety
 *   Crash-tracking functions are not reentrant.
 *   No other crash-handler functions should be called concurrently.
 * # Atomicity
 *   This function is not atomic. A crash during its execution may lead to
 *   unexpected crash-handling behaviour.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_init(struct ddog_crasht_Config config,
                                        struct ddog_crasht_ReceiverConfig receiver_config,
                                        struct ddog_crasht_Metadata metadata);

/**
 * Reconfigure the crashtracker and re-enables it.
 * If the crashtracker has not been initialized, this function will have no effect.
 *
 * # Preconditions
 *   None.
 * # Safety
 *   Crash-tracking functions are not reentrant.
 *   No other crash-handler functions should be called concurrently.
 * # Atomicity
 *   This function is not atomic. A crash during its execution may lead to
 *   unexpected crash-handling behaviour.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_reconfigure(struct ddog_crasht_Config config,
                                               struct ddog_crasht_ReceiverConfig receiver_config,
                                               struct ddog_crasht_Metadata metadata);

/**
 * Initialize the crash-tracking infrastructure without launching the receiver.
 *
 * # Preconditions
 *   Requires `config` to be given with a `unix_socket_path`, which is normally optional.
 * # Safety
 *   Crash-tracking functions are not reentrant.
 *   No other crash-handler functions should be called concurrently.
 * # Atomicity
 *   This function is not atomic. A crash during its execution may lead to
 *   unexpected crash-handling behaviour.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_init_without_receiver(struct ddog_crasht_Config config,
                                                         struct ddog_crasht_Metadata metadata);

/**
 * Returns a list of signals suitable for use in a crashtracker config.
 */
struct ddog_crasht_Slice_CInt ddog_crasht_default_signals(void);

/**
 * Removes all existing additional tags
 * Expected to be used after a fork, to reset the additional tags on the child
 * ATOMICITY:
 *     This is NOT ATOMIC.
 *     Should only be used when no conflicting updates can occur,
 *     e.g. after a fork but before profiling ops start on the child.
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_clear_additional_tags(void);

/**
 * Atomically registers a string as an additional tag.
 * Useful for tracking what operations were occurring when a crash occurred.
 * The set does not check for duplicates.
 *
 * Returns:
 *   Ok(handle) on success.  The handle is needed to later remove the id;
 *   Err() on failure. The most likely cause of failure is that the underlying set is full.
 *
 * # Safety
 * The string argument must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_crasht_Result_Usize ddog_crasht_insert_additional_tag(ddog_CharSlice s);

/**
 * Atomically removes a completed SpanId.
 * Useful for tracking what operations were occurring when a crash occurred.
 * 0 is reserved for "NoId"
 *
 * Returns:
 *   `Ok` on success.
 *   `Err` on failure.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_remove_additional_tag(uintptr_t idx);

/**
 * Resets all counters to 0.
 * Expected to be used after a fork, to reset the counters on the child
 * ATOMICITY:
 *     This is NOT ATOMIC.
 *     Should only be used when no conflicting updates can occur,
 *     e.g. after a fork but before profiling ops start on the child.
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_reset_counters(void);

/**
 * Atomically increments the count associated with `op`.
 * Useful for tracking what operations were occuring when a crash occurred.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_begin_op(enum ddog_crasht_OpTypes op);

/**
 * Atomically decrements the count associated with `op`.
 * Useful for tracking what operations were occuring when a crash occurred.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_end_op(enum ddog_crasht_OpTypes op);

/**
 * Resets all stored spans to 0.
 * Expected to be used after a fork, to reset the spans on the child
 * ATOMICITY:
 *     This is NOT ATOMIC.
 *     Should only be used when no conflicting updates can occur,
 *     e.g. after a fork but before profiling ops start on the child.
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_clear_span_ids(void);

/**
 * Resets all stored traces to 0.
 * Expected to be used after a fork, to reset the traces on the child
 * ATOMICITY:
 *     This is NOT ATOMIC.
 *     Should only be used when no conflicting updates can occur,
 *     e.g. after a fork but before profiling ops start on the child.
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_clear_trace_ids(void);

/**
 * Atomically registers an active traceId.
 * Useful for tracking what operations were occurring when a crash occurred.
 * 0 is reserved for "NoId"
 * The set does not check for duplicates.  Adding the same id twice is an error.
 *
 * Inputs:
 * id<high/low>: the 128 bit id, broken into 2 64 bit chunks (see note)
 *
 * Returns:
 *   Ok(handle) on success.  The handle is needed to later remove the id;
 *   Err() on failure. The most likely cause of failure is that the underlying set is full.
 *
 * Note: 128 bit ints in FFI were not stabilized until Rust 1.77
 * https://blog.rust-lang.org/2024/03/30/i128-layout-update.html
 * We're currently locked into 1.76.0, have to do an ugly workaround involving 2 64 bit ints
 * until we can upgrade.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN
struct ddog_crasht_Result_Usize ddog_crasht_insert_trace_id(uint64_t id_high,
                                                            uint64_t id_low);

/**
 * Atomically registers an active SpanId.
 * Useful for tracking what operations were occurring when a crash occurred.
 * 0 is reserved for "NoId".
 * The set does not check for duplicates.  Adding the same id twice is an error.
 *
 * Inputs:
 * id<high/low>: the 128 bit id, broken into 2 64 bit chunks (see note)
 *
 * Returns:
 *   Ok(handle) on success.  The handle is needed to later remove the id;
 *   Err() on failure. The most likely cause of failure is that the underlying set is full.
 *
 * Note: 128 bit ints in FFI were not stabilized until Rust 1.77
 * https://blog.rust-lang.org/2024/03/30/i128-layout-update.html
 * We're currently locked into 1.76.0, have to do an ugly workaround involving 2 64 bit ints
 * until we can upgrade.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN
struct ddog_crasht_Result_Usize ddog_crasht_insert_span_id(uint64_t id_high,
                                                           uint64_t id_low);

/**
 * Atomically removes a completed SpanId.
 * Useful for tracking what operations were occurring when a crash occurred.
 * 0 is reserved for "NoId"
 *
 * Inputs:
 * id<high/low>: the 128 bit id, broken into 2 64 bit chunks (see note)
 * idx: The handle for the id, from a previous successful call to `insert_span_id`.
 *      Attempting to remove the same element twice is an error.
 * Returns:
 *   `Ok` on success.
 *   `Err` on failure.  If `id` is not found at `idx`, `Err` will be returned and the set will not
 *                      be modified.
 *
 * Note: 128 bit ints in FFI were not stabilized until Rust 1.77
 * https://blog.rust-lang.org/2024/03/30/i128-layout-update.html
 * We're currently locked into 1.76.0, have to do an ugly workaround involving 2 64 bit ints
 * until we can upgrade.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_remove_span_id(uint64_t id_high,
                                                  uint64_t id_low,
                                                  uintptr_t idx);

/**
 * Atomically removes a completed TraceId.
 * Useful for tracking what operations were occurring when a crash occurred.
 * 0 is reserved for "NoId"
 *
 * Inputs:
 * id<high/low>: the 128 bit id, broken into 2 64 bit chunks (see note)
 * idx: The handle for the id, from a previous successful call to `insert_span_id`.
 *      Attempting to remove the same element twice is an error.
 * Returns:
 *   `Ok` on success.
 *   `Err` on failure.  If `id` is not found at `idx`, `Err` will be returned and the set will not
 *                      be modified.
 *
 * Note: 128 bit ints in FFI were not stabilized until Rust 1.77
 * https://blog.rust-lang.org/2024/03/30/i128-layout-update.html
 * We're currently locked into 1.76.0, have to do an ugly workaround involving 2 64 bit ints
 * until we can upgrade.
 *
 * # Safety
 * No safety concerns.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_remove_trace_id(uint64_t id_high,
                                                   uint64_t id_low,
                                                   uintptr_t idx);

#if (defined(_CRASHTRACKING_COLLECTOR) && defined(_WIN32))
/**
 * Initialize the crash-tracking infrastructure.
 *
 * # Preconditions
 *   None.
 * # Safety
 *   Crash-tracking functions are not reentrant.
 *   No other crash-handler functions should be called concurrently.
 * # Atomicity
 *   This function is not atomic. A crash during its execution may lead to
 *   unexpected crash-handling behaviour.
 */
DDOG_CHECK_RETURN
bool ddog_crasht_init_windows(ddog_CharSlice module,
                              const struct ddog_Endpoint *endpoint,
                              struct ddog_crasht_Metadata metadata);
#endif

#if (defined(_CRASHTRACKING_COLLECTOR) && defined(_WIN32))
HRESULT OutOfProcessExceptionEventSignatureCallback(const void *_context,
                                                    const WER_RUNTIME_EXCEPTION_INFORMATION *_exception_information,
                                                    int32_t _index,
                                                    uint16_t *_name,
                                                    uint32_t *_name_size,
                                                    uint16_t *_value,
                                                    uint32_t *_value_size);
#endif

#if (defined(_CRASHTRACKING_COLLECTOR) && defined(_WIN32))
HRESULT OutOfProcessExceptionEventDebuggerLaunchCallback(const void *_context,
                                                         const WER_RUNTIME_EXCEPTION_INFORMATION *_exception_information,
                                                         BOOL *_is_custom_debugger,
                                                         uint16_t *_debugger_launch,
                                                         uint32_t *_debugger_launch_size,
                                                         BOOL *_is_debugger_auto_launch);
#endif

#if (defined(_CRASHTRACKING_COLLECTOR) && defined(_WIN32))
HRESULT OutOfProcessExceptionEventCallback(const void *context,
                                           const WER_RUNTIME_EXCEPTION_INFORMATION *exception_information,
                                           BOOL *_ownership_claimed,
                                           uint16_t *_event_name,
                                           uint32_t *_size,
                                           uint32_t *_signature_count);
#endif

/**
 * # Safety
 * The `crash_info` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfo_demangle_names(struct ddog_crasht_Handle_CrashInfo *crash_info);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Frame
 * made by this module, which has not previously been dropped.
 */
void ddog_crasht_CrashInfo_drop(struct ddog_crasht_Handle_CrashInfo *builder);

/**
 * # Safety
 * The `crash_info` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfo_normalize_ips(struct ddog_crasht_Handle_CrashInfo *crash_info,
                                                           uint32_t pid);

/**
 * # Safety
 * The `crash_info` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfo_resolve_names(struct ddog_crasht_Handle_CrashInfo *crash_info,
                                                           uint32_t pid);

/**
 * # Safety
 * The `crash_info` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfo_upload_to_endpoint(struct ddog_crasht_Handle_CrashInfo *crash_info,
                                                                const struct ddog_Endpoint *endpoint);

/**
 * Create a new CrashInfoBuilder, and returns an opaque reference to it.
 * # Safety
 * No safety issues.
 */
DDOG_CHECK_RETURN
struct  ddog_crasht_CrashInfoBuilder_NewResult ddog_crasht_CrashInfoBuilder_new(void);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Frame
 * made by this module, which has not previously been dropped.
 */
void ddog_crasht_CrashInfoBuilder_drop(struct ddog_crasht_Handle_CrashInfoBuilder *builder);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_crasht_CrashInfo_NewResult ddog_crasht_CrashInfoBuilder_build(struct ddog_crasht_Handle_CrashInfoBuilder *builder);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_counter(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                 ddog_CharSlice name,
                                                                 int64_t value);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The Kind must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_kind(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                              enum ddog_crasht_ErrorKind kind);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_file(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                              ddog_CharSlice filename);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_file_and_contents(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                           ddog_CharSlice filename,
                                                                           struct ddog_crasht_Slice_CharSlice contents);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_fingerprint(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                     ddog_CharSlice fingerprint);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_incomplete(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                    bool incomplete);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_log_message(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                     ddog_CharSlice message,
                                                                     bool also_print);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_metadata(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                  struct ddog_crasht_Metadata metadata);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_os_info(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                 struct ddog_crasht_OsInfo os_info);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_os_info_this_machine(struct ddog_crasht_Handle_CrashInfoBuilder *builder);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_proc_info(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                   struct ddog_crasht_ProcInfo proc_info);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_sig_info(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                  struct ddog_crasht_SigInfo sig_info);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_span_id(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                 struct ddog_crasht_Span span_id);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 * Consumes the stack argument.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_stack(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                               struct ddog_crasht_Handle_StackTrace *stack);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 * Consumes the stack argument.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_thread(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                struct ddog_crasht_ThreadData thread);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_timestamp(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                   struct ddog_Timespec ts);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_timestamp_now(struct ddog_crasht_Handle_CrashInfoBuilder *builder);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * All arguments must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_trace_id(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                                  struct ddog_crasht_Span trace_id);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_uuid(struct ddog_crasht_Handle_CrashInfoBuilder *builder,
                                                              ddog_CharSlice uuid);

/**
 * # Safety
 * The `builder` can be null, but if non-null it must point to a Builder made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_CrashInfoBuilder_with_uuid_random(struct ddog_crasht_Handle_CrashInfoBuilder *builder);

/**
 * Create a new StackFrame, and returns an opaque reference to it.
 * # Safety
 * No safety issues.
 */
DDOG_CHECK_RETURN struct ddog_crasht_StackFrame_NewResult ddog_crasht_StackFrame_new(void);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame
 * made by this module, which has not previously been dropped.
 */
void ddog_crasht_StackFrame_drop(struct ddog_crasht_Handle_StackFrame *frame);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_ip(struct ddog_crasht_Handle_StackFrame *frame,
                                                      uintptr_t ip);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_module_base_address(struct ddog_crasht_Handle_StackFrame *frame,
                                                                       uintptr_t module_base_address);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_sp(struct ddog_crasht_Handle_StackFrame *frame,
                                                      uintptr_t sp);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_symbol_address(struct ddog_crasht_Handle_StackFrame *frame,
                                                                  uintptr_t symbol_address);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_build_id(struct ddog_crasht_Handle_StackFrame *frame,
                                                            ddog_CharSlice build_id);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The BuildIdType must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_build_id_type(struct ddog_crasht_Handle_StackFrame *frame,
                                                                 enum ddog_crasht_BuildIdType build_id_type);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The FileType must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_file_type(struct ddog_crasht_Handle_StackFrame *frame,
                                                             enum ddog_crasht_FileType file_type);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_path(struct ddog_crasht_Handle_StackFrame *frame,
                                                        ddog_CharSlice path);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_relative_address(struct ddog_crasht_Handle_StackFrame *frame,
                                                                    uintptr_t relative_address);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_column(struct ddog_crasht_Handle_StackFrame *frame,
                                                          uint32_t column);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_file(struct ddog_crasht_Handle_StackFrame *frame,
                                                        ddog_CharSlice file);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The CharSlice must be valid.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_function(struct ddog_crasht_Handle_StackFrame *frame,
                                                            ddog_CharSlice function);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackFrame_with_line(struct ddog_crasht_Handle_StackFrame *frame,
                                                        uint32_t line);

/**
 * Create a new StackTrace, and returns an opaque reference to it.
 * # Safety
 * No safety issues.
 */
DDOG_CHECK_RETURN struct  ddog_crasht_StackTrace_NewResult ddog_crasht_StackTrace_new(void);

/**
 * # Safety
 * The `frame` can be null, but if non-null it must point to a Frame
 * made by this module, which has not previously been dropped.
 */
void ddog_crasht_StackTrace_drop(struct ddog_crasht_Handle_StackTrace *trace);

/**
 * # Safety
 * The `stacktrace` can be null, but if non-null it must point to a StackTrace made by this module,
 * which has not previously been dropped.
 * The frame can be non-null, but if non-null it must point to a Frame made by this module,
 * which has not previously been dropped.
 * The frame is consumed, and does not need to be dropped after this operation.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackTrace_push_frame(struct ddog_crasht_Handle_StackTrace *trace,
                                                         struct ddog_crasht_Handle_StackFrame *frame,
                                                         bool incomplete);

/**
 * # Safety
 * The `stacktrace` can be null, but if non-null it must point to a StackTrace made by this module,
 * which has not previously been dropped.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_StackTrace_set_complete(struct ddog_crasht_Handle_StackTrace *trace);

/**
 * Demangles the string "name".
 * If demangling fails, returns an empty string ""
 *
 * # Safety
 * `name` should be a valid reference to a utf8 encoded String.
 * The string is copied into the result, and does not need to outlive this call
 */
DDOG_CHECK_RETURN
struct ddog_StringWrapperResult ddog_crasht_demangle(ddog_CharSlice name,
                                                     enum ddog_crasht_DemangleOptions options);

/**
 * Receives data from a crash collector via a pipe on `stdin`, formats it into
 * `CrashInfo` json, and emits it to the endpoint/file defined in `config`.
 *
 * At a high-level, this exists because doing anything in a
 * signal handler is dangerous, so we fork a sidecar to do the stuff we aren't
 * allowed to do in the handler.
 *
 * See comments in [datadog-crashtracker/lib.rs] for a full architecture description.
 * # Safety
 * No safety concerns
 */
DDOG_CHECK_RETURN struct ddog_VoidResult ddog_crasht_receiver_entry_point_stdin(void);

/**
 * Receives data from a crash collector via a pipe on `stdin`, formats it into
 * `CrashInfo` json, and emits it to the endpoint/file defined in `config`.
 *
 * At a high-level, this exists because doing anything in a
 * signal handler is dangerous, so we fork a sidecar to do the stuff we aren't
 * allowed to do in the handler.
 *
 * See comments in [datadog-crashtracker/lib.rs] for a full architecture
 * description.
 * # Safety
 * No safety concerns
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_crasht_receiver_entry_point_unix_socket(ddog_CharSlice socket_path);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  /* DDOG_CRASHTRACKER_H */
