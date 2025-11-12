"use strict";
/*
 * Constants
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SURVEYS_REQUEST_TIMEOUT_MS = exports.PERSISTENCE_RESERVED_PROPERTIES = exports.WEB_EXPERIMENTS = exports.COOKIELESS_MODE_FLAG_PROPERTY = exports.COOKIELESS_SENTINEL_VALUE = exports.TOOLBAR_CONTAINER_CLASS = exports.TOOLBAR_ID = exports.ENABLE_PERSON_PROCESSING = exports.INITIAL_PERSON_INFO = exports.INITIAL_REFERRER_INFO = exports.INITIAL_CAMPAIGN_PARAMS = exports.CAPTURE_RATE_LIMIT = exports.CLIENT_SESSION_PROPS = exports.USER_STATE = exports.FLAG_CALL_REPORTED = exports.SURVEYS_ACTIVATED = exports.SURVEYS = exports.STORED_GROUP_PROPERTIES_KEY = exports.STORED_PERSON_PROPERTIES_KEY = exports.PERSISTENCE_FEATURE_FLAG_DETAILS = exports.PERSISTENCE_EARLY_ACCESS_FEATURES = exports.ENABLED_FEATURE_FLAGS = exports.SESSION_RECORDING_EVENT_TRIGGER_STATUS = exports.SESSION_RECORDING_EVENT_TRIGGER_ACTIVATED_SESSION = exports.SESSION_RECORDING_URL_TRIGGER_STATUS = exports.SESSION_RECORDING_URL_TRIGGER_ACTIVATED_SESSION = exports.SESSION_RECORDING_IS_SAMPLED = exports.SESSION_ID = exports.SESSION_RECORDING_SCRIPT_CONFIG = exports.SESSION_RECORDING_MINIMUM_DURATION = exports.SESSION_RECORDING_SAMPLE_RATE = exports.SESSION_RECORDING_CANVAS_RECORDING = exports.SESSION_RECORDING_MASKING = exports.SESSION_RECORDING_NETWORK_PAYLOAD_CAPTURE = exports.CONSOLE_LOG_RECORDING_ENABLED_SERVER_SIDE = exports.SESSION_RECORDING_ENABLED_SERVER_SIDE = exports.WEB_VITALS_ALLOWED_METRICS = exports.DEAD_CLICKS_ENABLED_SERVER_SIDE = exports.WEB_VITALS_ENABLED_SERVER_SIDE = exports.ERROR_TRACKING_CAPTURE_EXTENSION_EXCEPTIONS = exports.ERROR_TRACKING_SUPPRESSION_RULES = exports.EXCEPTION_CAPTURE_ENABLED_SERVER_SIDE = exports.HEATMAPS_ENABLED_SERVER_SIDE = exports.AUTOCAPTURE_DISABLED_SERVER_SIDE = exports.EVENT_TIMERS_KEY = exports.CAMPAIGN_IDS_KEY = exports.ALIAS_ID_KEY = exports.DISTINCT_ID = exports.PEOPLE_DISTINCT_ID_KEY = void 0;
/* PROPERTY KEYS */
// This key is deprecated, but we want to check for it to see whether aliasing is allowed.
exports.PEOPLE_DISTINCT_ID_KEY = '$people_distinct_id';
exports.DISTINCT_ID = 'distinct_id';
exports.ALIAS_ID_KEY = '__alias';
exports.CAMPAIGN_IDS_KEY = '__cmpns';
exports.EVENT_TIMERS_KEY = '__timers';
exports.AUTOCAPTURE_DISABLED_SERVER_SIDE = '$autocapture_disabled_server_side';
exports.HEATMAPS_ENABLED_SERVER_SIDE = '$heatmaps_enabled_server_side';
exports.EXCEPTION_CAPTURE_ENABLED_SERVER_SIDE = '$exception_capture_enabled_server_side';
exports.ERROR_TRACKING_SUPPRESSION_RULES = '$error_tracking_suppression_rules';
exports.ERROR_TRACKING_CAPTURE_EXTENSION_EXCEPTIONS = '$error_tracking_capture_extension_exceptions';
exports.WEB_VITALS_ENABLED_SERVER_SIDE = '$web_vitals_enabled_server_side';
exports.DEAD_CLICKS_ENABLED_SERVER_SIDE = '$dead_clicks_enabled_server_side';
exports.WEB_VITALS_ALLOWED_METRICS = '$web_vitals_allowed_metrics';
exports.SESSION_RECORDING_ENABLED_SERVER_SIDE = '$session_recording_enabled_server_side';
exports.CONSOLE_LOG_RECORDING_ENABLED_SERVER_SIDE = '$console_log_recording_enabled_server_side';
exports.SESSION_RECORDING_NETWORK_PAYLOAD_CAPTURE = '$session_recording_network_payload_capture';
exports.SESSION_RECORDING_MASKING = '$session_recording_masking';
exports.SESSION_RECORDING_CANVAS_RECORDING = '$session_recording_canvas_recording';
exports.SESSION_RECORDING_SAMPLE_RATE = '$replay_sample_rate';
exports.SESSION_RECORDING_MINIMUM_DURATION = '$replay_minimum_duration';
exports.SESSION_RECORDING_SCRIPT_CONFIG = '$replay_script_config';
exports.SESSION_ID = '$sesid';
exports.SESSION_RECORDING_IS_SAMPLED = '$session_is_sampled';
exports.SESSION_RECORDING_URL_TRIGGER_ACTIVATED_SESSION = '$session_recording_url_trigger_activated_session';
exports.SESSION_RECORDING_URL_TRIGGER_STATUS = '$session_recording_url_trigger_status';
exports.SESSION_RECORDING_EVENT_TRIGGER_ACTIVATED_SESSION = '$session_recording_event_trigger_activated_session';
exports.SESSION_RECORDING_EVENT_TRIGGER_STATUS = '$session_recording_event_trigger_status';
exports.ENABLED_FEATURE_FLAGS = '$enabled_feature_flags';
exports.PERSISTENCE_EARLY_ACCESS_FEATURES = '$early_access_features';
exports.PERSISTENCE_FEATURE_FLAG_DETAILS = '$feature_flag_details';
exports.STORED_PERSON_PROPERTIES_KEY = '$stored_person_properties';
exports.STORED_GROUP_PROPERTIES_KEY = '$stored_group_properties';
exports.SURVEYS = '$surveys';
exports.SURVEYS_ACTIVATED = '$surveys_activated';
exports.FLAG_CALL_REPORTED = '$flag_call_reported';
exports.USER_STATE = '$user_state';
exports.CLIENT_SESSION_PROPS = '$client_session_props';
exports.CAPTURE_RATE_LIMIT = '$capture_rate_limit';
/** @deprecated Delete this when INITIAL_PERSON_INFO has been around for long enough to ignore backwards compat */
exports.INITIAL_CAMPAIGN_PARAMS = '$initial_campaign_params';
/** @deprecated Delete this when INITIAL_PERSON_INFO has been around for long enough to ignore backwards compat */
exports.INITIAL_REFERRER_INFO = '$initial_referrer_info';
exports.INITIAL_PERSON_INFO = '$initial_person_info';
exports.ENABLE_PERSON_PROCESSING = '$epp';
exports.TOOLBAR_ID = '__POSTHOG_TOOLBAR__';
exports.TOOLBAR_CONTAINER_CLASS = 'toolbar-global-fade-container';
/**
 * PREVIEW - MAY CHANGE WITHOUT WARNING - DO NOT USE IN PRODUCTION
 * Sentinel value for distinct id, device id, session id. Signals that the server should generate the value
 * */
exports.COOKIELESS_SENTINEL_VALUE = '$posthog_cookieless';
exports.COOKIELESS_MODE_FLAG_PROPERTY = '$cookieless_mode';
exports.WEB_EXPERIMENTS = '$web_experiments';
// These are properties that are reserved and will not be automatically included in events
exports.PERSISTENCE_RESERVED_PROPERTIES = [
    exports.PEOPLE_DISTINCT_ID_KEY,
    exports.ALIAS_ID_KEY,
    exports.CAMPAIGN_IDS_KEY,
    exports.EVENT_TIMERS_KEY,
    exports.SESSION_RECORDING_ENABLED_SERVER_SIDE,
    exports.HEATMAPS_ENABLED_SERVER_SIDE,
    exports.SESSION_ID,
    exports.ENABLED_FEATURE_FLAGS,
    exports.ERROR_TRACKING_SUPPRESSION_RULES,
    exports.USER_STATE,
    exports.PERSISTENCE_EARLY_ACCESS_FEATURES,
    exports.PERSISTENCE_FEATURE_FLAG_DETAILS,
    exports.STORED_GROUP_PROPERTIES_KEY,
    exports.STORED_PERSON_PROPERTIES_KEY,
    exports.SURVEYS,
    exports.FLAG_CALL_REPORTED,
    exports.CLIENT_SESSION_PROPS,
    exports.CAPTURE_RATE_LIMIT,
    exports.INITIAL_CAMPAIGN_PARAMS,
    exports.INITIAL_REFERRER_INFO,
    exports.ENABLE_PERSON_PROCESSING,
    exports.INITIAL_PERSON_INFO,
];
exports.SURVEYS_REQUEST_TIMEOUT_MS = 10000;
//# sourceMappingURL=constants.js.map