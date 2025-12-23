// Copyright 2021-Present Datadog, Inc. https://www.datadoghq.com/
// SPDX-License-Identifier: Apache-2.0


#ifndef DDOG_TELEMETRY_H
#define DDOG_TELEMETRY_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "common.h"

/**
 * # Safety
 * * builder should be a non null pointer to a null pointer to a builder
 */
ddog_MaybeError ddog_telemetry_builder_instantiate(struct ddog_TelemetryWorkerBuilder **out_builder,
                                                   ddog_CharSlice service_name,
                                                   ddog_CharSlice language_name,
                                                   ddog_CharSlice language_version,
                                                   ddog_CharSlice tracer_version);

/**
 * # Safety
 * * builder should be a non null pointer to a null pointer to a builder
 */
ddog_MaybeError ddog_telemetry_builder_instantiate_with_hostname(struct ddog_TelemetryWorkerBuilder **out_builder,
                                                                 ddog_CharSlice hostname,
                                                                 ddog_CharSlice service_name,
                                                                 ddog_CharSlice language_name,
                                                                 ddog_CharSlice language_version,
                                                                 ddog_CharSlice tracer_version);

ddog_MaybeError ddog_telemetry_builder_with_native_deps(struct ddog_TelemetryWorkerBuilder *builder,
                                                        bool include_native_deps);

ddog_MaybeError ddog_telemetry_builder_with_rust_shared_lib_deps(struct ddog_TelemetryWorkerBuilder *builder,
                                                                 bool include_rust_shared_lib_deps);

ddog_MaybeError ddog_telemetry_builder_with_config(struct ddog_TelemetryWorkerBuilder *builder,
                                                   ddog_CharSlice name,
                                                   ddog_CharSlice value,
                                                   enum ddog_ConfigurationOrigin origin,
                                                   ddog_CharSlice config_id);

/**
 * Builds the telemetry worker and return a handle to it
 *
 * # Safety
 * * handle should be a non null pointer to a null pointer
 */
ddog_MaybeError ddog_telemetry_builder_run(struct ddog_TelemetryWorkerBuilder *builder,
                                           struct ddog_TelemetryWorkerHandle **out_handle);

/**
 * Builds the telemetry worker and return a handle to it. The worker will only process and send
 * telemetry metrics and telemetry logs. Any lifecyle/dependency/configuration event will be
 * ignored
 *
 * # Safety
 * * handle should be a non null pointer to a null pointer
 */
ddog_MaybeError ddog_telemetry_builder_run_metric_logs(struct ddog_TelemetryWorkerBuilder *builder,
                                                       struct ddog_TelemetryWorkerHandle **out_handle);

ddog_MaybeError ddog_telemetry_builder_with_endpoint_config_endpoint(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                     const struct ddog_Endpoint *endpoint);

/**
 * Sets a property from it's string value.
 *
 * Available properties:
 *
 * * config.endpoint
 */
ddog_MaybeError ddog_telemetry_builder_with_property_endpoint(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                              enum ddog_TelemetryWorkerBuilderEndpointProperty _property,
                                                              const struct ddog_Endpoint *endpoint);

/**
 * Sets a property from it's string value.
 *
 * Available properties:
 *
 * * config.endpoint
 */
ddog_MaybeError ddog_telemetry_builder_with_endpoint_named_property(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                    ddog_CharSlice property,
                                                                    const struct ddog_Endpoint *endpoint);

ddog_MaybeError ddog_telemetry_builder_with_str_application_service_version(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                            ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_application_env(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_application_runtime_name(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                         ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_application_runtime_version(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                            ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_application_runtime_patches(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                            ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_host_container_id(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                  ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_host_os(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                        ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_host_kernel_name(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                 ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_host_kernel_release(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                    ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_host_kernel_version(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                    ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_str_runtime_id(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                           ddog_CharSlice param);

/**
 *      Sets a property from it's string value.
 *
 *     Available properties:
 *
 *     * application.service_version
 *
 *     * application.env
 *
 *     * application.runtime_name
 *
 *     * application.runtime_version
 *
 *     * application.runtime_patches
 *
 *     * host.container_id
 *
 *     * host.os
 *
 *     * host.kernel_name
 *
 *     * host.kernel_release
 *
 *     * host.kernel_version
 *
 *     * runtime_id
 *
 *
 */
ddog_MaybeError ddog_telemetry_builder_with_property_str(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                         enum ddog_TelemetryWorkerBuilderStrProperty property,
                                                         ddog_CharSlice param);

/**
 *      Sets a property from it's string value.
 *
 *     Available properties:
 *
 *     * application.service_version
 *
 *     * application.env
 *
 *     * application.runtime_name
 *
 *     * application.runtime_version
 *
 *     * application.runtime_patches
 *
 *     * host.container_id
 *
 *     * host.os
 *
 *     * host.kernel_name
 *
 *     * host.kernel_release
 *
 *     * host.kernel_version
 *
 *     * runtime_id
 *
 *
 */
ddog_MaybeError ddog_telemetry_builder_with_str_named_property(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                               ddog_CharSlice property,
                                                               ddog_CharSlice param);

ddog_MaybeError ddog_telemetry_builder_with_bool_config_telemetry_debug_logging_enabled(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                                        bool param);

/**
 *      Sets a property from it's string value.
 *
 *     Available properties:
 *
 *     * config.telemetry_debug_logging_enabled
 *
 *
 */
ddog_MaybeError ddog_telemetry_builder_with_property_bool(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                          enum ddog_TelemetryWorkerBuilderBoolProperty property,
                                                          bool param);

/**
 *      Sets a property from it's string value.
 *
 *     Available properties:
 *
 *     * config.telemetry_debug_logging_enabled
 *
 *
 */
ddog_MaybeError ddog_telemetry_builder_with_bool_named_property(struct ddog_TelemetryWorkerBuilder *telemetry_builder,
                                                                ddog_CharSlice property,
                                                                bool param);

ddog_MaybeError ddog_telemetry_handle_add_dependency(const struct ddog_TelemetryWorkerHandle *handle,
                                                     ddog_CharSlice dependency_name,
                                                     ddog_CharSlice dependency_version);

ddog_MaybeError ddog_telemetry_handle_add_integration(const struct ddog_TelemetryWorkerHandle *handle,
                                                      ddog_CharSlice dependency_name,
                                                      ddog_CharSlice dependency_version,
                                                      bool enabled,
                                                      struct ddog_Option_Bool compatible,
                                                      struct ddog_Option_Bool auto_enabled);

/**
 * * indentifier: identifies a logging location uniquely. This can for instance be the template
 *   using for the log message or the concatenated file + line of the origin of the log
 * * stack_trace: stack trace associated with the log. If no stack trace is available, an empty
 *   string should be passed
 */
ddog_MaybeError ddog_telemetry_handle_add_log(const struct ddog_TelemetryWorkerHandle *handle,
                                              ddog_CharSlice indentifier,
                                              ddog_CharSlice message,
                                              enum ddog_LogLevel level,
                                              ddog_CharSlice stack_trace);

ddog_MaybeError ddog_telemetry_handle_start(const struct ddog_TelemetryWorkerHandle *handle);

struct ddog_TelemetryWorkerHandle *ddog_telemetry_handle_clone(const struct ddog_TelemetryWorkerHandle *handle);

ddog_MaybeError ddog_telemetry_handle_stop(const struct ddog_TelemetryWorkerHandle *handle);

/**
 * * compatible: should be false if the metric is language specific, true otherwise
 */
struct ddog_ContextKey ddog_telemetry_handle_register_metric_context(const struct ddog_TelemetryWorkerHandle *handle,
                                                                     ddog_CharSlice name,
                                                                     enum ddog_MetricType metric_type,
                                                                     struct ddog_Vec_Tag tags,
                                                                     bool common,
                                                                     enum ddog_MetricNamespace namespace_);

ddog_MaybeError ddog_telemetry_handle_add_point(const struct ddog_TelemetryWorkerHandle *handle,
                                                const struct ddog_ContextKey *context_key,
                                                double value);

ddog_MaybeError ddog_telemetry_handle_add_point_with_tags(const struct ddog_TelemetryWorkerHandle *handle,
                                                          const struct ddog_ContextKey *context_key,
                                                          double value,
                                                          struct ddog_Vec_Tag extra_tags);

/**
 * This function takes ownership of the handle. It should not be used after calling it
 */
void ddog_telemetry_handle_wait_for_shutdown(struct ddog_TelemetryWorkerHandle *handle);

/**
 * This function takes ownership of the handle. It should not be used after calling it
 */
void ddog_telemetry_handle_wait_for_shutdown_ms(struct ddog_TelemetryWorkerHandle *handle,
                                                uint64_t wait_for_ms);

/**
 * Drops the handle without waiting for shutdown. The worker will continue running in the
 * background until it exits by itself
 */
void ddog_telemetry_handle_drop(struct ddog_TelemetryWorkerHandle *handle);

#endif  /* DDOG_TELEMETRY_H */
