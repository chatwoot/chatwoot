// Copyright 2021-Present Datadog, Inc. https://www.datadoghq.com/
// SPDX-License-Identifier: Apache-2.0


#ifndef DDOG_LIBRARY_CONFIG_H
#define DDOG_LIBRARY_CONFIG_H

#pragma once

#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

struct ddog_Configurator *ddog_library_configurator_new(bool debug_logs, ddog_CharSlice language);

void ddog_library_configurator_with_local_path(struct ddog_Configurator *c,
                                               struct ddog_CStr local_path);

void ddog_library_configurator_with_fleet_path(struct ddog_Configurator *c,
                                               struct ddog_CStr local_path);

void ddog_library_configurator_with_process_info(struct ddog_Configurator *c,
                                                 struct ddog_ProcessInfo p);

void ddog_library_configurator_with_detect_process_info(struct ddog_Configurator *c);

void ddog_library_configurator_drop(struct ddog_Configurator*);

struct ddog_Result_VecLibraryConfig ddog_library_configurator_get(const struct ddog_Configurator *configurator);

/**
 * Returns a static null-terminated string, containing the name of the environment variable
 * associated with the library configuration
 */
struct ddog_CStr ddog_library_config_source_to_string(enum ddog_LibraryConfigSource name);

/**
 * Returns a static null-terminated string with the path to the managed stable config yaml config
 * file
 */
struct ddog_CStr ddog_library_config_fleet_stable_config_path(void);

/**
 * Returns a static null-terminated string with the path to the local stable config yaml config
 * file
 */
struct ddog_CStr ddog_library_config_local_stable_config_path(void);

void ddog_library_config_drop(struct ddog_Vec_LibraryConfig);

/**
 * Store tracer metadata to a file handle
 *
 * # Safety
 *
 * Accepts raw C-compatible strings
 */
struct ddog_Result_TracerMemfdHandle ddog_store_tracer_metadata(uint8_t schema_version,
                                                                ddog_CharSlice runtime_id,
                                                                ddog_CharSlice tracer_language,
                                                                ddog_CharSlice tracer_version,
                                                                ddog_CharSlice hostname,
                                                                ddog_CharSlice service_name,
                                                                ddog_CharSlice service_env,
                                                                ddog_CharSlice service_version);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  /* DDOG_LIBRARY_CONFIG_H */
