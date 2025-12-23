// Copyright 2021-Present Datadog, Inc. https://www.datadoghq.com/
// SPDX-License-Identifier: Apache-2.0


#ifndef DDOG_PROFILING_H
#define DDOG_PROFILING_H

#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "common.h"
struct TokioCancellationToken;


#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

extern const ddog_prof_StringId INTERNED_EMPTY_STRING;

DDOG_CHECK_RETURN struct ddog_prof_Exporter_Slice_File ddog_prof_Exporter_Slice_File_empty(void);

/**
 * Creates an endpoint that uses the agent.
 * # Arguments
 * * `base_url` - Contains a URL with scheme, host, and port e.g. "https://agent:8126/".
 */
struct ddog_prof_Endpoint ddog_prof_Endpoint_agent(ddog_CharSlice base_url);

/**
 * Creates an endpoint that uses the Datadog intake directly aka agentless.
 * # Arguments
 * * `site` - Contains a host and port e.g. "datadoghq.com".
 * * `api_key` - Contains the Datadog API key.
 */
struct ddog_prof_Endpoint ddog_prof_Endpoint_agentless(ddog_CharSlice site, ddog_CharSlice api_key);

/**
 * Creates an endpoint that writes to a file.
 * Useful for local debugging.
 * Currently only supported by the crashtracker.
 * # Arguments
 * * `filename` - Path to the output file "/tmp/file.txt".
 */
struct ddog_prof_Endpoint ddog_Endpoint_file(ddog_CharSlice filename);

/**
 * Creates a new exporter to be used to report profiling data.
 * # Arguments
 * * `profiling_library_name` - Profiling library name, usually dd-trace-something, e.g.
 *   "dd-trace-rb". See
 *   https://datadoghq.atlassian.net/wiki/spaces/PROF/pages/1538884229/Client#Header-values
 *   (Datadog internal link)
 *   for a list of common values.
 * * `profliling_library_version` - Version used when publishing the profiling library to a package
 *   manager
 * * `family` - Profile family, e.g. "ruby"
 * * `tags` - Tags to include with every profile reported by this exporter. It's also possible to
 *   include profile-specific tags, see `additional_tags` on `profile_exporter_build`.
 * * `endpoint` - Configuration for reporting data
 * # Safety
 * All pointers must refer to valid objects of the correct types.
 */
DDOG_CHECK_RETURN
struct ddog_prof_ProfileExporter_Result ddog_prof_Exporter_new(ddog_CharSlice profiling_library_name,
                                                               ddog_CharSlice profiling_library_version,
                                                               ddog_CharSlice family,
                                                               const struct ddog_Vec_Tag *tags,
                                                               struct ddog_prof_Endpoint endpoint);

/**
 * Sets the value for the exporter's timeout.
 * # Arguments
 * * `exporter` - ProfileExporter instance.
 * * `timeout_ms` - timeout in milliseconds.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_prof_Exporter_set_timeout(struct ddog_prof_ProfileExporter *exporter,
                                                      uint64_t timeout_ms);

/**
 * # Safety
 * The `exporter` may be null, but if non-null the pointer must point to a
 * valid `ddog_prof_Exporter_Request` object made by the Rust Global
 * allocator that has not already been dropped.
 */
void ddog_prof_Exporter_drop(struct ddog_prof_ProfileExporter *exporter);

/**
 * If successful, builds a `ddog_prof_Exporter_Request` object based on the
 * profile data supplied. If unsuccessful, it returns an error message.
 *
 * For details on the `optional_internal_metadata_json`, please reference the Datadog-internal
 * "RFC: Attaching internal metadata to pprof profiles".
 * If you use this parameter, please update the RFC with your use-case, so we can keep track of how
 * this is getting used.
 *
 * For details on the `optional_info_json`, please reference the Datadog-internal
 * "RFC: Pprof System Info Support".
 *
 * # Safety
 * The `exporter`, `optional_additional_stats`, and `optional_endpoint_stats` args should be
 * valid objects created by this module.
 * NULL is allowed for `optional_additional_tags`, `optional_endpoints_stats`,
 * `optional_internal_metadata_json` and `optional_info_json`.
 * Consumes the `SerializedProfile`
 */
DDOG_CHECK_RETURN
struct ddog_prof_Request_Result ddog_prof_Exporter_Request_build(struct ddog_prof_ProfileExporter *exporter,
                                                                 struct ddog_prof_EncodedProfile *profile,
                                                                 struct ddog_prof_Exporter_Slice_File files_to_compress_and_export,
                                                                 struct ddog_prof_Exporter_Slice_File files_to_export_unmodified,
                                                                 const struct ddog_Vec_Tag *optional_additional_tags,
                                                                 const ddog_CharSlice *optional_internal_metadata_json,
                                                                 const ddog_CharSlice *optional_info_json);

/**
 * # Safety
 * Each pointer of `request` may be null, but if non-null the inner-most
 * pointer must point to a valid `ddog_prof_Exporter_Request` object made by
 * the Rust Global allocator.
 */
void ddog_prof_Exporter_Request_drop(struct ddog_prof_Request *request);

/**
 * Sends the request, returning the HttpStatus.
 *
 * # Arguments
 * * `exporter` - Borrows the exporter for sending the request.
 * * `request` - Takes ownership of the request, replacing it with a null pointer. This is why it
 *   takes a double-pointer, rather than a single one.
 * * `cancel` - Borrows the cancel, if any.
 *
 * # Safety
 * All non-null arguments MUST have been created by created by apis in this module.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Result_HttpStatus ddog_prof_Exporter_send(struct ddog_prof_ProfileExporter *exporter,
                                                           struct ddog_prof_Request *request,
                                                           struct ddog_CancellationToken *cancel);

/**
 * Can be passed as an argument to send and then be used to asynchronously cancel it from a
 * different thread.
 */
DDOG_CHECK_RETURN struct ddog_CancellationToken ddog_CancellationToken_new(void);

/**
 * A cloned TokioCancellationToken is connected to the TokioCancellationToken it was created from.
 * Either the cloned or the original token can be used to cancel or provided as arguments to send.
 * The useful part is that they have independent lifetimes and can be dropped separately.
 *
 * Thus, it's possible to do something like:
 * ```c
 * cancel_t1 = ddog_CancellationToken_new();
 * cancel_t2 = ddog_CancellationToken_clone(cancel_t1);
 *
 * // On thread t1:
 *     ddog_prof_Exporter_send(..., cancel_t1);
 *     ddog_CancellationToken_drop(cancel_t1);
 *
 * // On thread t2:
 *     ddog_CancellationToken_cancel(cancel_t2);
 *     ddog_CancellationToken_drop(cancel_t2);
 * ```
 *
 * Without clone, both t1 and t2 would need to synchronize to make sure neither was using the
 * cancel before it could be dropped. With clone, there is no need for such synchronization, both
 * threads have their own cancel and should drop that cancel after they are done with it.
 *
 * # Safety
 * If the `token` is non-null, it must point to a valid object.
 */
DDOG_CHECK_RETURN
struct ddog_CancellationToken ddog_CancellationToken_clone(struct ddog_CancellationToken *token);

/**
 * Cancel send that is being called in another thread with the given token.
 * Note that cancellation is a terminal state; cancelling a token more than once does nothing.
 * Returns `true` if token was successfully cancelled.
 */
bool ddog_CancellationToken_cancel(struct ddog_CancellationToken *cancel);

/**
 * # Safety
 * The `token` can be null, but non-null values must be created by the Rust
 * Global allocator and must have not been dropped already.
 */
void ddog_CancellationToken_drop(struct ddog_CancellationToken *token);

/**
 * Create a new profile with the given sample types. Must call
 * `ddog_prof_Profile_drop` when you are done with the profile.
 *
 * # Arguments
 * * `sample_types`
 * * `period` - Optional period of the profile. Passing None/null translates to zero values.
 * * `start_time` - Optional time the profile started at. Passing None/null will use the current
 *   time.
 *
 * # Safety
 * All slices must be have pointers that are suitably aligned for their type
 * and must have the correct number of elements for the slice.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_NewResult ddog_prof_Profile_new(struct ddog_prof_Slice_ValueType sample_types,
                                                         const struct ddog_prof_Period *period);

/**
 * Same as `ddog_profile_new` but also configures a `string_storage` for the profile.
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_NewResult ddog_prof_Profile_with_string_storage(struct ddog_prof_Slice_ValueType sample_types,
                                                                         const struct ddog_prof_Period *period,
                                                                         struct ddog_prof_ManagedStringStorage string_storage);

/**
 * # Safety
 * The `profile` can be null, but if non-null it must point to a Profile
 * made by this module, which has not previously been dropped.
 */
void ddog_prof_Profile_drop(struct ddog_prof_Profile *profile);

/**
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module. All pointers inside the `sample` need to be valid for the duration
 * of this call.
 *
 * If successful, it returns the Ok variant.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_Result ddog_prof_Profile_add(struct ddog_prof_Profile *profile,
                                                      struct ddog_prof_Sample sample,
                                                      int64_t timestamp);

/**
 * Associate an endpoint to a given local root span id.
 * During the serialization of the profile, an endpoint label will be added
 * to all samples that contain a matching local root span id label.
 *
 * Note: calling this API causes the "trace endpoint" and "local root span id" strings
 * to be interned, even if no matching sample is found.
 *
 * # Arguments
 * * `profile` - a reference to the profile that will contain the samples.
 * * `local_root_span_id`
 * * `endpoint` - the value of the endpoint label to add for matching samples.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_Result ddog_prof_Profile_set_endpoint(struct ddog_prof_Profile *profile,
                                                               uint64_t local_root_span_id,
                                                               ddog_CharSlice endpoint);

/**
 * Count the number of times an endpoint has been seen.
 *
 * # Arguments
 * * `profile` - a reference to the profile that will contain the samples.
 * * `endpoint` - the endpoint label for which the count will be incremented
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_Result ddog_prof_Profile_add_endpoint_count(struct ddog_prof_Profile *profile,
                                                                     ddog_CharSlice endpoint,
                                                                     int64_t value);

/**
 * Add a poisson-based upscaling rule which will be use to adjust values and make them
 * closer to reality.
 *
 * # Arguments
 * * `profile` - a reference to the profile that will contain the samples.
 * * `offset_values` - offset of the values
 * * `label_name` - name of the label used to identify sample(s)
 * * `label_value` - value of the label used to identify sample(s)
 * * `sum_value_offset` - offset of the value used as a sum (compute the average with
 *   `count_value_offset`)
 * * `count_value_offset` - offset of the value used as a count (compute the average with
 *   `sum_value_offset`)
 * * `sampling_distance` - this is the threshold for this sampling window. This value must not be
 *   equal to 0
 *
 * # Safety
 * This function must be called before serialize and must not be called after.
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_Result ddog_prof_Profile_add_upscaling_rule_poisson(struct ddog_prof_Profile *profile,
                                                                             struct ddog_prof_Slice_Usize offset_values,
                                                                             ddog_CharSlice label_name,
                                                                             ddog_CharSlice label_value,
                                                                             uintptr_t sum_value_offset,
                                                                             uintptr_t count_value_offset,
                                                                             uint64_t sampling_distance);

/**
 * Add a proportional-based upscaling rule which will be use to adjust values and make them
 * closer to reality.
 *
 * # Arguments
 * * `profile` - a reference to the profile that will contain the samples.
 * * `offset_values` - offset of the values
 * * `label_name` - name of the label used to identify sample(s)
 * * `label_value` - value of the label used to identify sample(s)
 * * `total_sampled` - number of sampled event (found in the pprof). This value must not be equal
 *   to 0
 * * `total_real` - number of events the profiler actually witnessed. This value must not be equal
 *   to 0
 *
 * # Safety
 * This function must be called before serialize and must not be called after.
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_Result ddog_prof_Profile_add_upscaling_rule_proportional(struct ddog_prof_Profile *profile,
                                                                                  struct ddog_prof_Slice_Usize offset_values,
                                                                                  ddog_CharSlice label_name,
                                                                                  ddog_CharSlice label_value,
                                                                                  uint64_t total_sampled,
                                                                                  uint64_t total_real);

/**
 * # Safety
 * Only pass a reference to a valid `ddog_prof_EncodedProfile`, or null. A
 * valid reference also means that it hasn't already been dropped or exported (do not
 * call this twice on the same object).
 */
void ddog_prof_EncodedProfile_drop(struct ddog_prof_EncodedProfile *profile);

/**
 * Given an EncodedProfile, get a slice representing the bytes in the pprof.
 * This slice is valid for use until the encoded_profile is modified in any way (e.g. dropped or
 * consumed).
 * # Safety
 * Only pass a reference to a valid `ddog_prof_EncodedProfile`.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Result_ByteSlice ddog_prof_EncodedProfile_bytes(struct ddog_prof_EncodedProfile *encoded_profile);

/**
 * Serialize the aggregated profile.
 * Drains the data, and then resets the profile for future use.
 *
 * Don't forget to clean up the ok with `ddog_prof_EncodedProfile_drop` or
 * the error variant with `ddog_Error_drop` when you are done with them.
 *
 * # Arguments
 * * `profile` - a reference to the profile being serialized.
 * * `start_time` - start time for the serialized profile.
 * * `end_time` - optional end time of the profile. If None/null is passed, the current time will
 *   be used.
 *
 * # Safety
 * The `profile` must point to a valid profile object.
 * The `start_time` and `end_time` must be null or otherwise point to a valid TimeSpec object.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_SerializeResult ddog_prof_Profile_serialize(struct ddog_prof_Profile *profile,
                                                                     const struct ddog_Timespec *start_time,
                                                                     const struct ddog_Timespec *end_time);

DDOG_CHECK_RETURN struct ddog_Slice_U8 ddog_Vec_U8_as_slice(const struct ddog_Vec_U8 *vec);

/**
 * Resets all data in `profile` except the sample types and period. Returns
 * true if it successfully reset the profile and false otherwise. The profile
 * remains valid if false is returned.
 *
 * # Arguments
 * * `profile` - A mutable reference to the profile to be reset.
 * * `start_time` - The time of the profile (after reset). Pass None/null to use the current time.
 *
 * # Safety
 * The `profile` must meet all the requirements of a mutable reference to the profile. Given this
 * can be called across an FFI boundary, the compiler cannot enforce this.
 * If `time` is not null, it must point to a valid Timespec object.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Profile_Result ddog_prof_Profile_reset(struct ddog_prof_Profile *profile);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_FunctionId_Result ddog_prof_Profile_intern_function(struct ddog_prof_Profile *profile,
                                                                     struct ddog_prof_StringId name,
                                                                     struct ddog_prof_StringId system_name,
                                                                     struct ddog_prof_StringId filename);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_LabelId_Result ddog_prof_Profile_intern_label_num(struct ddog_prof_Profile *profile,
                                                                   struct ddog_prof_StringId key,
                                                                   int64_t val);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_LabelId_Result ddog_prof_Profile_intern_label_num_with_unit(struct ddog_prof_Profile *profile,
                                                                             struct ddog_prof_StringId key,
                                                                             int64_t val,
                                                                             struct ddog_prof_StringId unit);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_LabelId_Result ddog_prof_Profile_intern_label_str(struct ddog_prof_Profile *profile,
                                                                   struct ddog_prof_StringId key,
                                                                   struct ddog_prof_StringId val);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_LabelSetId_Result ddog_prof_Profile_intern_labelset(struct ddog_prof_Profile *profile,
                                                                     struct ddog_prof_Slice_LabelId labels);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_LocationId_Result ddog_prof_Profile_intern_location(struct ddog_prof_Profile *profile,
                                                                     struct ddog_prof_FunctionId function_id,
                                                                     uint64_t address,
                                                                     int64_t line);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_LocationId_Result ddog_prof_Profile_intern_location_with_mapping_id(struct ddog_prof_Profile *profile,
                                                                                     struct ddog_prof_MappingId mapping_id,
                                                                                     struct ddog_prof_FunctionId function_id,
                                                                                     uint64_t address,
                                                                                     int64_t line);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_StringId_Result ddog_prof_Profile_intern_managed_string(struct ddog_prof_Profile *profile,
                                                                         struct ddog_prof_ManagedStringId s);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_prof_Profile_intern_managed_strings(struct ddog_prof_Profile *profile,
                                                                struct ddog_prof_Slice_ManagedStringId strings,
                                                                struct ddog_prof_MutSlice_GenerationalIdStringId out);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_MappingId_Result ddog_prof_Profile_intern_mapping(struct ddog_prof_Profile *profile,
                                                                   uint64_t memory_start,
                                                                   uint64_t memory_limit,
                                                                   uint64_t file_offset,
                                                                   struct ddog_prof_StringId filename,
                                                                   struct ddog_prof_StringId build_id);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns void.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_prof_Profile_intern_sample(struct ddog_prof_Profile *profile,
                                                       struct ddog_prof_StackTraceId stacktrace,
                                                       struct ddog_Slice_I64 values,
                                                       struct ddog_prof_LabelSetId labels,
                                                       int64_t timestamp);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_StackTraceId_Result ddog_prof_Profile_intern_stacktrace(struct ddog_prof_Profile *profile,
                                                                         struct ddog_prof_Slice_LocationId locations);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_StringId_Result ddog_prof_Profile_intern_string(struct ddog_prof_Profile *profile,
                                                                 ddog_CharSlice s);

/**
 * This functions returns an interned id for an empty string
 *
 * # Safety
 * No preconditions
 */
struct ddog_prof_StringId ddog_prof_Profile_interned_empty_string(void);

/**
 * This function interns its argument into the profiler.
 * If successful, it returns an opaque interning ID.
 * This ID is valid for use on this profiler, until the profiler is reset.
 * It is an error to use this id after the profiler has been reset, or on a different profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * All other arguments must remain valid for the length of this call.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_prof_Profile_intern_strings(struct ddog_prof_Profile *profile,
                                                        struct ddog_prof_Slice_CharSlice strings,
                                                        struct ddog_prof_MutSlice_GenerationalIdStringId out);

/**
 * This functions returns the current generation of the profiler.
 * On error, it holds an error message in the error variant.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is _NOT_ thread-safe.
 */
DDOG_CHECK_RETURN
struct ddog_prof_Result_Generation ddog_prof_Profile_get_generation(struct ddog_prof_Profile *profile);

/**
 * This functions returns whether the given generations are equal.
 *
 * # Safety: No safety requirements
 */
DDOG_CHECK_RETURN
bool ddog_prof_Profile_generations_are_equal(struct ddog_prof_Generation a,
                                             struct ddog_prof_Generation b);

/**
 * This functions ends the current sample and allows the profiler exporter to continue, if it was
 * blocked.
 * It must have been paired with exactly one `sample_start`.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is probably thread-safe, but I haven't confirmed this.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_prof_Profile_sample_end(struct ddog_prof_Profile *profile);

/**
 * This functions starts a sample and blocks the exporter from continuing.
 *
 * # Safety
 * The `profile` ptr must point to a valid Profile object created by this
 * module.
 * This call is probably thread-safe, but I haven't confirmed this.
 */
DDOG_CHECK_RETURN
struct ddog_VoidResult ddog_prof_Profile_sample_start(struct ddog_prof_Profile *profile);

DDOG_CHECK_RETURN
struct ddog_prof_ManagedStringStorageNewResult ddog_prof_ManagedStringStorage_new(void);

/**
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
void ddog_prof_ManagedStringStorage_drop(struct ddog_prof_ManagedStringStorage storage);

/**
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
DDOG_CHECK_RETURN
struct ddog_prof_ManagedStringStorageInternResult ddog_prof_ManagedStringStorage_intern(struct ddog_prof_ManagedStringStorage storage,
                                                                                        ddog_CharSlice string);

/**
 * Interns all the strings in `strings`, writing the resulting id to the same
 * offset in `output_ids`.
 *
 * This can fail if:
 *  1. The given `output_ids_size` doesn't match the size of the input slice.
 *  2. The internal storage pointer is null.
 *  3. It fails to acquire a lock (e.g. it was poisoned).
 *  4. Defensive checks against bugs fail.
 *
 * If a failure occurs, do not use any of the ids in the output array. After
 * this point, you should only use read-only routines (except for drop) on
 * the managed string storage.
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
ddog_prof_MaybeError ddog_prof_ManagedStringStorage_intern_all(struct ddog_prof_ManagedStringStorage storage,
                                                               struct ddog_prof_Slice_CharSlice strings,
                                                               struct ddog_prof_ManagedStringId *output_ids,
                                                               uintptr_t output_ids_size);

/**
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
ddog_prof_MaybeError ddog_prof_ManagedStringStorage_unintern(struct ddog_prof_ManagedStringStorage storage,
                                                             struct ddog_prof_ManagedStringId id);

/**
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
ddog_prof_MaybeError ddog_prof_ManagedStringStorage_unintern_all(struct ddog_prof_ManagedStringStorage storage,
                                                                 struct ddog_prof_Slice_ManagedStringId ids);

/**
 * Returns a string given its id.
 * This API is mostly for testing, overall you should avoid reading back strings from libdatadog
 * once they've been interned and should instead always operate on the id.
 * Remember to `ddog_StringWrapper_drop` the string once you're done with it.
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
DDOG_CHECK_RETURN
struct ddog_StringWrapperResult ddog_prof_ManagedStringStorage_get_string(struct ddog_prof_ManagedStringStorage storage,
                                                                          struct ddog_prof_ManagedStringId id);

/**
 * TODO: @ivoanjo Should this take a `*mut ManagedStringStorage` like Profile APIs do?
 */
ddog_prof_MaybeError ddog_prof_ManagedStringStorage_advance_gen(struct ddog_prof_ManagedStringStorage storage);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  /* DDOG_PROFILING_H */
