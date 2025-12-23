// Copyright 2021-Present Datadog, Inc. https://www.datadoghq.com/
// SPDX-License-Identifier: Apache-2.0


#ifndef DDOG_DATA_PIPELINE_H
#define DDOG_DATA_PIPELINE_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * Frees `error` and all its contents. After being called error will not point to a valid memory
 * address so any further actions on it could lead to undefined behavior.
 */
void ddog_trace_exporter_error_free(struct ddog_TraceExporterError *error);

/**
 * Return a read-only pointer to the response body. This pointer is only valid as long as
 * `response` is valid.
 */
const char *ddog_trace_exporter_response_get_body(const struct ddog_TraceExporterResponse *response);

/**
 * Free `response` and all its contents. After being called response will not point to a valid
 * memory address so any further actions on it could lead to undefined behavior.
 */
void ddog_trace_exporter_response_free(struct ddog_TraceExporterResponse *response);

void ddog_trace_exporter_config_new(struct ddog_TraceExporterConfig **out_handle);

/**
 * Frees TraceExporterConfig handle internal resources.
 */
void ddog_trace_exporter_config_free(struct ddog_TraceExporterConfig *handle);

/**
 * Sets traces destination.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_url(struct ddog_TraceExporterConfig *config,
                                                                   ddog_CharSlice url);

/**
 * Sets tracer's version to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_tracer_version(struct ddog_TraceExporterConfig *config,
                                                                              ddog_CharSlice version);

/**
 * Sets tracer's language to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_language(struct ddog_TraceExporterConfig *config,
                                                                        ddog_CharSlice lang);

/**
 * Sets tracer's language version to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_lang_version(struct ddog_TraceExporterConfig *config,
                                                                            ddog_CharSlice version);

/**
 * Sets tracer's language interpreter to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_lang_interpreter(struct ddog_TraceExporterConfig *config,
                                                                                ddog_CharSlice interpreter);

/**
 * Sets hostname information to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_hostname(struct ddog_TraceExporterConfig *config,
                                                                        ddog_CharSlice hostname);

/**
 * Sets environmet information to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_env(struct ddog_TraceExporterConfig *config,
                                                                   ddog_CharSlice env);

struct ddog_TraceExporterError *ddog_trace_exporter_config_set_version(struct ddog_TraceExporterConfig *config,
                                                                       ddog_CharSlice version);

/**
 * Sets service name to be included in the headers request.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_service(struct ddog_TraceExporterConfig *config,
                                                                       ddog_CharSlice service);

/**
 * Enables metrics.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_enable_telemetry(struct ddog_TraceExporterConfig *config,
                                                                            const struct ddog_TelemetryClientConfig *telemetry_cfg);

/**
 * Set client-side stats computation status.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_compute_stats(struct ddog_TraceExporterConfig *config,
                                                                             bool is_enabled);

/**
 * Sets `Datadog-Client-Computed-Stats` header to `true`.
 * This indicates that the upstream system has already computed the stats,
 * and no further stats computation should be performed.
 *
 * <div class="warning">
 * This method must not be used when `compute_stats` is enabled, as it could
 * result in duplicate stats computation.
 * </div>
 *
 * A common use case is in Application Security Monitoring (ASM) scenarios:
 * when APM is disabled but ASM is enabled, setting this header to `true`
 * ensures that no stats are computed at any level (exporter or agent).
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_client_computed_stats(struct ddog_TraceExporterConfig *config,
                                                                                     bool client_computed_stats);

/**
 * Sets the `X-Datadog-Test-Session-Token` header. Only used for testing with the test agent.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_config_set_test_session_token(struct ddog_TraceExporterConfig *config,
                                                                                  ddog_CharSlice token);

/**
 * Create a new TraceExporter instance.
 *
 * # Arguments
 *
 * * `out_handle` - The handle to write the TraceExporter instance in.
 * * `config` - The configuration used to set up the TraceExporter handle.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_new(struct ddog_TraceExporter **out_handle,
                                                        const struct ddog_TraceExporterConfig *config);

/**
 * Free the TraceExporter instance.
 *
 * # Arguments
 *
 * * handle - The handle to the TraceExporter instance.
 */
void ddog_trace_exporter_free(struct ddog_TraceExporter *handle);

/**
 * Send traces to the Datadog Agent.
 *
 * # Arguments
 *
 * * `handle` - The handle to the TraceExporter instance.
 * * `trace` - The traces to send to the Datadog Agent in the input format used to create the
 *   TraceExporter. The memory for the trace must be valid for the life of the call to this
 *   function.
 * * `trace_count` - The number of traces to send to the Datadog Agent.
 * * `response_out` - Optional handle to store a pointer to the agent response information.
 */
struct ddog_TraceExporterError *ddog_trace_exporter_send(const struct ddog_TraceExporter *handle,
                                                         ddog_ByteSlice trace,
                                                         uintptr_t trace_count,
                                                         struct ddog_TraceExporterResponse **response_out);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  /* DDOG_DATA_PIPELINE_H */
