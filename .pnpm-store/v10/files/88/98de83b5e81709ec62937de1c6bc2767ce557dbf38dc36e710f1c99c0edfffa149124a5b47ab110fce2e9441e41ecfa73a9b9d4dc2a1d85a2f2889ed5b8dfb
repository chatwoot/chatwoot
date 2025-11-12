import { eventWithTime, blockClass, maskTextClass, hooksParam, PackFn, SamplingStrategy, RecordPlugin, KeepIframeSrcFn } from '@rrweb/types';
import { KnownUnsafeEditableEvent } from '@posthog/core';

declare class RageClick {
    clicks: {
        x: number;
        y: number;
        timestamp: number;
    }[];
    constructor();
    isRageClick(x: number, y: number, timestamp: number): boolean;
}

type MaskInputOptions = Partial<{
    color: boolean;
    date: boolean;
    'datetime-local': boolean;
    email: boolean;
    month: boolean;
    number: boolean;
    range: boolean;
    search: boolean;
    tel: boolean;
    text: boolean;
    time: boolean;
    url: boolean;
    week: boolean;
    textarea: boolean;
    select: boolean;
    password: boolean;
}>;
type MaskInputFn = (text: string, element: HTMLElement) => string;
type MaskTextFn = (text: string, element: HTMLElement | null) => string;
type SlimDOMOptions = Partial<{
    script: boolean;
    comment: boolean;
    headFavicon: boolean;
    headWhitespace: boolean;
    headMetaDescKeywords: boolean;
    headMetaSocial: boolean;
    headMetaRobots: boolean;
    headMetaHttpEquiv: boolean;
    headMetaAuthorship: boolean;
    headMetaVerification: boolean;
    headTitleMutations: boolean;
}>;
type DataURLOptions = Partial<{
    type: string;
    quality: number;
}>;
type ErrorHandler = (error: unknown) => void | boolean;
type recordOptions = {
    emit?: (e: eventWithTime, isCheckout?: boolean) => void;
    checkoutEveryNth?: number;
    checkoutEveryNms?: number;
    blockClass?: blockClass;
    blockSelector?: string;
    ignoreClass?: string;
    ignoreSelector?: string;
    maskTextClass?: maskTextClass;
    maskTextSelector?: string;
    maskAllInputs?: boolean;
    maskInputOptions?: MaskInputOptions;
    maskInputFn?: MaskInputFn;
    maskTextFn?: MaskTextFn;
    slimDOMOptions?: SlimDOMOptions | 'all' | true;
    ignoreCSSAttributes?: Set<string>;
    inlineStylesheet?: boolean;
    hooks?: hooksParam;
    packFn?: PackFn;
    sampling?: SamplingStrategy;
    dataURLOptions?: DataURLOptions;
    recordDOM?: boolean;
    recordCanvas?: boolean;
    recordCrossOriginIframes?: boolean;
    recordAfter?: 'DOMContentLoaded' | 'load';
    userTriggeredOnInput?: boolean;
    collectFonts?: boolean;
    inlineImages?: boolean;
    plugins?: RecordPlugin[];
    mousemoveWait?: number;
    keepIframeSrcFn?: KeepIframeSrcFn;
    errorHandler?: ErrorHandler;
};

/**
 * Extend Segment with extra PostHog JS functionality. Required for things like Recordings and feature flags to work correctly.
 *
 * ### Usage
 *
 *  ```js
 *  // After your standard segment anyalytics install
 *  analytics.load("GOEDfA21zZTtR7clsBuDvmBKAtAdZ6Np");
 *
 *  analytics.ready(() => {
 *    posthog.init('<posthog-api-key>', {
 *      capture_pageview: false,
 *      segment: window.analytics, // NOTE: Be sure to use window.analytics here!
 *    });
 *    window.analytics.page();
 *  })
 *  ```
 */

type SegmentUser = {
    anonymousId(): string | undefined;
    id(): string | undefined;
};
type SegmentAnalytics = {
    user: () => SegmentUser | Promise<SegmentUser>;
    register: (integration: SegmentPlugin) => Promise<void>;
};
interface SegmentContext {
    event: {
        event: string;
        userId?: string;
        anonymousId?: string;
        properties: any;
    };
}
type SegmentFunction = (ctx: SegmentContext) => Promise<SegmentContext> | SegmentContext;
interface SegmentPlugin {
    name: string;
    version: string;
    type: 'enrichment';
    isLoaded: () => boolean;
    load: (ctx: SegmentContext, instance: any, config?: any) => Promise<unknown>;
    unload?: (ctx: SegmentContext, instance: any) => Promise<unknown> | unknown;
    ready?: () => Promise<unknown>;
    track?: SegmentFunction;
    identify?: SegmentFunction;
    page?: SegmentFunction;
    group?: SegmentFunction;
    alias?: SegmentFunction;
    screen?: SegmentFunction;
}

/**
 * Having Survey types in types.ts was confusing tsc
 * and generating an invalid module.d.ts
 * See https://github.com/PostHog/posthog-js/issues/698
 */

declare enum SurveyWidgetType {
    Button = "button",
    Tab = "tab",
    Selector = "selector"
}
declare enum SurveyPosition {
    TopLeft = "top_left",
    TopRight = "top_right",
    TopCenter = "top_center",
    MiddleLeft = "middle_left",
    MiddleRight = "middle_right",
    MiddleCenter = "middle_center",
    Left = "left",
    Center = "center",
    Right = "right",
    NextToTrigger = "next_to_trigger"
}
interface SurveyAppearance {
    backgroundColor?: string;
    submitButtonColor?: string;
    textColor?: string;
    submitButtonText?: string;
    submitButtonTextColor?: string;
    descriptionTextColor?: string;
    ratingButtonColor?: string;
    ratingButtonActiveColor?: string;
    ratingButtonHoverColor?: string;
    whiteLabel?: boolean;
    autoDisappear?: boolean;
    displayThankYouMessage?: boolean;
    thankYouMessageHeader?: string;
    thankYouMessageDescription?: string;
    thankYouMessageDescriptionContentType?: SurveyQuestionDescriptionContentType;
    thankYouMessageCloseButtonText?: string;
    borderColor?: string;
    position?: SurveyPosition;
    placeholder?: string;
    shuffleQuestions?: boolean;
    surveyPopupDelaySeconds?: number;
    widgetType?: SurveyWidgetType;
    widgetSelector?: string;
    widgetLabel?: string;
    widgetColor?: string;
    fontFamily?: string;
    maxWidth?: string;
    zIndex?: string;
    disabledButtonOpacity?: string;
    boxPadding?: string;
}
declare enum SurveyType {
    Popover = "popover",
    API = "api",
    Widget = "widget",
    ExternalSurvey = "external_survey"
}
type SurveyQuestion = BasicSurveyQuestion | LinkSurveyQuestion | RatingSurveyQuestion | MultipleSurveyQuestion;
type SurveyQuestionDescriptionContentType = 'html' | 'text';
interface SurveyQuestionBase {
    question: string;
    id?: string;
    description?: string | null;
    descriptionContentType?: SurveyQuestionDescriptionContentType;
    optional?: boolean;
    buttonText?: string;
    branching?: NextQuestionBranching | EndBranching | ResponseBasedBranching | SpecificQuestionBranching;
}
interface BasicSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.Open;
}
interface LinkSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.Link;
    link?: string | null;
}
interface RatingSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.Rating;
    display: 'number' | 'emoji';
    scale: 3 | 5 | 7 | 10;
    lowerBoundLabel: string;
    upperBoundLabel: string;
    skipSubmitButton?: boolean;
}
interface MultipleSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.SingleChoice | SurveyQuestionType.MultipleChoice;
    choices: string[];
    hasOpenChoice?: boolean;
    shuffleOptions?: boolean;
    skipSubmitButton?: boolean;
}
declare enum SurveyQuestionType {
    Open = "open",
    MultipleChoice = "multiple_choice",
    SingleChoice = "single_choice",
    Rating = "rating",
    Link = "link"
}
declare enum SurveyQuestionBranchingType {
    NextQuestion = "next_question",
    End = "end",
    ResponseBased = "response_based",
    SpecificQuestion = "specific_question"
}
interface NextQuestionBranching {
    type: SurveyQuestionBranchingType.NextQuestion;
}
interface EndBranching {
    type: SurveyQuestionBranchingType.End;
}
interface ResponseBasedBranching {
    type: SurveyQuestionBranchingType.ResponseBased;
    responseValues: Record<string, any>;
}
interface SpecificQuestionBranching {
    type: SurveyQuestionBranchingType.SpecificQuestion;
    index: number;
}
type SurveyCallback = (surveys: Survey[], context?: {
    isLoaded: boolean;
    error?: string;
}) => void;
interface SurveyElement {
    text?: string;
    $el_text?: string;
    tag_name?: string;
    href?: string;
    attr_id?: string;
    attr_class?: string[];
    nth_child?: number;
    nth_of_type?: number;
    attributes?: Record<string, any>;
    event_id?: number;
    order?: number;
    group_id?: number;
}
interface SurveyRenderReason {
    visible: boolean;
    disabledReason?: string;
}
declare enum SurveySchedule {
    Once = "once",
    Recurring = "recurring",
    Always = "always"
}
interface Survey {
    id: string;
    name: string;
    description: string;
    type: SurveyType;
    feature_flag_keys: {
        key: string;
        value?: string;
    }[] | null;
    linked_flag_key: string | null;
    targeting_flag_key: string | null;
    internal_targeting_flag_key: string | null;
    questions: SurveyQuestion[];
    appearance: SurveyAppearance | null;
    conditions: {
        url?: string;
        selector?: string;
        seenSurveyWaitPeriodInDays?: number;
        urlMatchType?: PropertyMatchType;
        events: {
            repeatedActivation?: boolean;
            values: {
                name: string;
            }[];
        } | null;
        actions: {
            values: SurveyActionType[];
        } | null;
        deviceTypes?: string[];
        deviceTypesMatchType?: PropertyMatchType;
        linkedFlagVariant?: string;
    } | null;
    start_date: string | null;
    end_date: string | null;
    current_iteration: number | null;
    current_iteration_start_date: string | null;
    schedule?: SurveySchedule | null;
    enable_partial_responses?: boolean | null;
}
type SurveyWithTypeAndAppearance = Pick<Survey, 'id' | 'type' | 'appearance'>;
interface SurveyActionType {
    id: number;
    name: string | null;
    steps?: ActionStepType[];
}
/** Sync with plugin-server/src/types.ts */
type ActionStepStringMatching = 'contains' | 'exact' | 'regex';
interface ActionStepType {
    event?: string | null;
    selector?: string | null;
    /** @deprecated Only `selector` should be used now. */
    tag_name?: string;
    text?: string | null;
    /** @default StringMatching.Exact */
    text_matching?: ActionStepStringMatching | null;
    href?: string | null;
    /** @default ActionStepStringMatching.Exact */
    href_matching?: ActionStepStringMatching | null;
    url?: string | null;
    /** @default StringMatching.Contains */
    url_matching?: ActionStepStringMatching | null;
}
declare enum SurveyEventName {
    SHOWN = "survey shown",
    DISMISSED = "survey dismissed",
    SENT = "survey sent"
}
declare enum SurveyEventProperties {
    SURVEY_ID = "$survey_id",
    SURVEY_NAME = "$survey_name",
    SURVEY_RESPONSE = "$survey_response",
    SURVEY_ITERATION = "$survey_iteration",
    SURVEY_ITERATION_START_DATE = "$survey_iteration_start_date",
    SURVEY_PARTIALLY_COMPLETED = "$survey_partially_completed",
    SURVEY_SUBMISSION_ID = "$survey_submission_id",
    SURVEY_QUESTIONS = "$survey_questions",
    SURVEY_COMPLETED = "$survey_completed"
}

type Property = any;
type Properties = Record<string, Property>;
declare const COPY_AUTOCAPTURE_EVENT = "$copy_autocapture";
/**
 * These are known events PostHog events that can be processed by the `beforeCapture` function
 * That means PostHog functionality does not rely on receiving 100% of these for calculations
 * So, it is safe to sample them to reduce the volume of events sent to PostHog
 */
type KnownEventName = '$heatmaps_data' | '$opt_in' | '$exception' | '$$heatmap' | '$web_vitals' | '$dead_click' | '$autocapture' | typeof COPY_AUTOCAPTURE_EVENT | '$rageclick';
type EventName = KnownUnsafeEditableEvent | KnownEventName | (string & {});
interface CaptureResult {
    uuid: string;
    event: EventName;
    properties: Properties;
    $set?: Properties;
    $set_once?: Properties;
    timestamp?: Date;
}
type AutocaptureCompatibleElement = 'a' | 'button' | 'form' | 'input' | 'select' | 'textarea' | 'label';
type DomAutocaptureEvents = 'click' | 'change' | 'submit';
/**
 * If an array is passed for an allowlist, autocapture events will only be sent for elements matching
 * at least one of the elements in the array. Multiple allowlists can be used
 */
interface AutocaptureConfig {
    /**
     * List of URLs to allow autocapture on, can be strings to match
     * or regexes e.g. ['https://example.com', 'test.com/.*']
     * this is useful when you want to autocapture on specific pages only
     *
     * if you set both url_allowlist and url_ignorelist,
     * we check the allowlist first and then the ignorelist.
     * the ignorelist can override the allowlist
     */
    url_allowlist?: (string | RegExp)[];
    /**
     * List of URLs to not allow autocapture on, can be strings to match
     * or regexes e.g. ['https://example.com', 'test.com/.*']
     * this is useful when you want to autocapture on most pages but not some specific ones
     *
     * if you set both url_allowlist and url_ignorelist,
     * we check the allowlist first and then the ignorelist.
     * the ignorelist can override the allowlist
     */
    url_ignorelist?: (string | RegExp)[];
    /**
     * List of DOM events to allow autocapture on  e.g. ['click', 'change', 'submit']
     */
    dom_event_allowlist?: DomAutocaptureEvents[];
    /**
     * List of DOM elements to allow autocapture on
     * e.g. ['a', 'button', 'form', 'input', 'select', 'textarea', 'label']
     *
     * We consider the tree of elements from the root to the target element of the click event
     * so for the tree `div > div > button > svg`
     * if the allowlist has `button` then we allow the capture when the `button` or the `svg` is the click target
     * but not if either of the `div`s are detected as the click target
     */
    element_allowlist?: AutocaptureCompatibleElement[];
    /**
     * List of CSS selectors to allow autocapture on
     * e.g. ['[ph-capture]']
     * we consider the tree of elements from the root to the target element of the click event
     * so for the tree div > div > button > svg
     * and allow list config `['[id]']`
     * we will capture the click if the click-target or its parents has any id
     *
     * Everything is allowed when there's no allowlist
     */
    css_selector_allowlist?: string[];
    /**
     * Exclude certain element attributes from autocapture
     * E.g. ['aria-label'] or [data-attr-pii]
     */
    element_attribute_ignorelist?: string[];
    /**
     * When set to true, autocapture will capture the text of any element that is cut or copied.
     */
    capture_copied_text?: boolean;
}
interface BootstrapConfig {
    distinctID?: string;
    isIdentifiedID?: boolean;
    featureFlags?: Record<string, boolean | string>;
    featureFlagPayloads?: Record<string, JsonType>;
    /**
     * Optionally provide a sessionID, this is so that you can provide an existing sessionID here to continue a user's session across a domain or device. It MUST be:
     * - unique to this user
     * - a valid UUID v7
     * - the timestamp part must be <= the timestamp of the first event in the session
     * - the timestamp of the last event in the session must be < the timestamp part + 24 hours
     * **/
    sessionID?: string;
}
type SupportedWebVitalsMetrics = 'LCP' | 'CLS' | 'FCP' | 'INP';
interface PerformanceCaptureConfig {
    /**
     *  Works with session replay to use the browser's native performance observer to capture performance metrics
     */
    network_timing?: boolean;
    /**
     * Use chrome's web vitals library to wrap fetch and capture web vitals
     */
    web_vitals?: boolean;
    /**
     * We observe very large values reported by the Chrome web vitals library
     * These outliers are likely not real, useful values, and we exclude them
     * You can set this to 0 in order to include all values, NB this is not recommended
     *
     * @default 15 * 60 * 1000 (15 minutes)
     */
    __web_vitals_max_value?: number;
    /**
     * By default all 4 metrics are captured
     * You can set this config to restrict which metrics are captured
     * e.g. ['CLS', 'FCP'] to only capture those two metrics
     * NB setting this does not override whether the capture is enabled
     *
     * @default ['LCP', 'CLS', 'FCP', 'INP']
     */
    web_vitals_allowed_metrics?: SupportedWebVitalsMetrics[];
    /**
     * We delay flushing web vitals metrics to reduce the number of events we send
     * This is the maximum time we will wait before sending the metrics
     *
     * @default 5000
     */
    web_vitals_delayed_flush_ms?: number;
}
interface DeadClickCandidate {
    node: Element;
    originalEvent: MouseEvent;
    timestamp: number;
    scrollDelayMs?: number;
    mutationDelayMs?: number;
    selectionChangedDelayMs?: number;
    absoluteDelayMs?: number;
}
type ExceptionAutoCaptureConfig = {
    /**
     * Determines whether PostHog should capture unhandled errors.
     *
     * @default true
     */
    capture_unhandled_errors: boolean;
    /**
     * Determines whether PostHog should capture unhandled promise rejections.
     *
     * @default true
     */
    capture_unhandled_rejections: boolean;
    /**
     * Determines whether PostHog should capture console errors.
     *
     * @default false
     */
    capture_console_errors: boolean;
};
type DeadClicksAutoCaptureConfig = {
    /**
     * We'll not consider a click to be a dead click, if it's followed by a scroll within `scroll_threshold_ms` milliseconds
     *
     * @default 100
     */
    scroll_threshold_ms?: number;
    /**
     * We'll not consider a click to be a dead click, if it's followed by a selection change within `selection_change_threshold_ms` milliseconds
     *
     * @default 100
     */
    selection_change_threshold_ms?: number;
    /**
     * We'll not consider a click to be a dead click, if it's followed by a mutation within `mutation_threshold_ms` milliseconds
     *
     * @default 2500
     */
    mutation_threshold_ms?: number;
    /**
     * Allows setting behavior for when a dead click is captured.
     * For e.g. to support capture to heatmaps
     *
     * If not provided the default behavior is to auto-capture dead click events
     *
     * Only intended to be provided by our own SDK
     */
    __onCapture?: ((click: DeadClickCandidate, properties: Properties) => void) | undefined;
} & Pick<AutocaptureConfig, 'element_attribute_ignorelist'>;
interface HeatmapConfig {
    /**
     * How often to send batched data in `$heatmap_data` events
     * If set to 0 or not set, sends using the default interval of 1 second
     *
     * @default 1000
     */
    flush_interval_milliseconds: number;
}
type BeforeSendFn = (cr: CaptureResult | null) => CaptureResult | null;
type ConfigDefaults = '2025-05-24' | 'unset';
type ExternalIntegrationKind = 'intercom' | 'crispChat';
/**
 * Configuration options for the PostHog JavaScript SDK.
 * @see https://posthog.com/docs/libraries/js#config
 */
interface PostHogConfig {
    /** URL of your PostHog instance.
     *
     * @default 'https://us.i.posthog.com'
     */
    api_host: string;
    /**
     * If using a reverse proxy for `api_host` then this should be the actual PostHog app URL (e.g. https://us.posthog.com).
     * This ensures that links to PostHog point to the correct host.
     *
     * @default null
     */
    ui_host: string | null;
    /**
     * The transport method to use for API requests.
     *
     * @default 'fetch'
     */
    api_transport?: 'XHR' | 'fetch';
    /**
     * The token for your PostHog project.
     * It should NOT be provided manually in the config, but rather passed as the first parameter to `posthog.init()`.
     */
    token: string;
    /**
     * The name this instance will be identified by.
     * You don't need to set this most of the time,
     * but can be useful if you have several Posthog instances running at the same time.
     *
     * @default 'posthog'
     */
    name: string;
    /**
     * Determines whether PostHog should autocapture events.
     * This setting does not affect capturing pageview events (see `capture_pageview`).
     *
     * @default true
     */
    autocapture: boolean | AutocaptureConfig;
    /**
     * Determines whether PostHog should capture rage clicks.
     *
     * @default true
     */
    rageclick: boolean;
    /**
     * Determines if cookie should be set on the top level domain (example.com).
     * If PostHog-js is loaded on a subdomain (test.example.com), and `cross_subdomain_cookie` is set to false,
     * it'll set the cookie on the subdomain only (test.example.com).
     *
     * NOTE: It will be set to `false` if we detect that the domain is a subdomain of a platform that is excluded from cross-subdomain cookie setting.
     * The current list of excluded platforms is `herokuapp.com`, `vercel.app`, and `netlify.app`.
     *
     * @see `isCrossDomainCookie`
     * @default true
     */
    cross_subdomain_cookie: boolean;
    /**
     * Determines how PostHog stores information about the user. See [persistence](https://posthog.com/docs/libraries/js#persistence) for details.
     *
     * @default 'localStorage+cookie'
     */
    persistence: 'localStorage' | 'cookie' | 'memory' | 'localStorage+cookie' | 'sessionStorage';
    /**
     * The name for the super properties persistent store
     *
     * @default ''
     */
    persistence_name: string;
    /** @deprecated - Use 'persistence_name' instead */
    cookie_name?: string;
    /**
     * A function to be called once the PostHog scripts have loaded successfully.
     *
     * @param posthog_instance - The PostHog instance that has been loaded.
     */
    loaded: (posthog_instance: PostHog) => void;
    /**
     * Determines whether PostHog should save referrer information.
     *
     * @default true
     */
    save_referrer: boolean;
    /**
     * Determines whether PostHog should save marketing parameters.
     * These are `utm_*` paramaters and friends.
     *
     * @see {CAMPAIGN_PARAMS} from './utils/event-utils' - Default campaign parameters like utm_source, utm_medium, etc.
     * @default true
     */
    save_campaign_params: boolean;
    /** @deprecated - Use `save_campaign_params` instead */
    store_google?: boolean;
    /**
     * Used to extend the list of campaign parameters that are saved by default.
     *
     * @see {CAMPAIGN_PARAMS} from './utils/event-utils' - Default campaign parameters like utm_source, utm_medium, etc.
     * @default []
     */
    custom_campaign_params: string[];
    /**
     * Used to extend the list of user agents that are blocked by default.
     *
     * @see {DEFAULT_BLOCKED_UA_STRS} from './utils/blocked-uas' - Default list of blocked user agents.
     * @default []
     */
    custom_blocked_useragents: string[];
    /**
     * Determines whether PostHog should be in debug mode.
     * You can enable this to get more detailed logging.
     *
     * You can also enable this on your website by appending `?__posthog_debug=true` at the end of your URL
     * You can also call `posthog.debug()` in your code to enable debug mode
     *
     * @default false
     */
    debug: boolean;
    /** @deprecated Use `debug` instead */
    verbose?: boolean;
    /**
     * Determines whether PostHog should capture pageview events automatically.
     * Can be:
     * - `true`: Capture regular pageviews (default)
     * - `false`: Don't capture any pageviews
     * - `'history_change'`: Only capture pageviews on history API changes (pushState, replaceState, popstate)
     *
     * @default true
     */
    capture_pageview: boolean | 'history_change';
    /**
     * Determines whether PostHog should capture pageleave events.
     * If set to `true`, it will capture pageleave events for all pages.
     * If set to `'if_capture_pageview'`, it will only capture pageleave events if `capture_pageview` is also set to `true` or `'history_change'`.
     *
     * @default 'if_capture_pageview'
     */
    capture_pageleave: boolean | 'if_capture_pageview';
    /**
     * Determines the number of days to store cookies for.
     *
     * @default 365
     */
    cookie_expiration: number;
    /**
     * Determines whether PostHog should upgrade old cookies.
     * If set to `true`, the library will check for a cookie from our old js library and import super properties from it, then the old cookie is deleted.
     * This option only works in the initialization, so make sure you set it when you create the library.
     *
     * @default false
     */
    upgrade: boolean;
    /**
     * Determines whether PostHog should disable session recording.
     *
     * @default false
     */
    disable_session_recording: boolean;
    /**
     * Determines whether PostHog should disable persistence.
     * If set to `true`, the library will not save any data to the browser. It will also delete any data previously saved to the browser.
     *
     * @default false
     */
    disable_persistence: boolean;
    /** @deprecated - use `disable_persistence` instead */
    disable_cookie?: boolean;
    /**
     * Determines whether PostHog should disable all surveys functionality.
     *
     * @default false
     */
    disable_surveys: boolean;
    /**
     * Determines whether PostHog should disable automatic display of surveys. If this is true, popup or widget surveys will not be shown when display conditions are met.
     *
     * @default false
     */
    disable_surveys_automatic_display: boolean;
    /**
     * Determines whether PostHog should disable web experiments.
     *
     * Currently disabled while we're in BETA. It will be toggled to `true` in a future release.
     *
     * @default true
     */
    disable_web_experiments: boolean;
    /**
     * Determines whether PostHog should disable any external dependency loading.
     * This will prevent PostHog from requesting any external scripts such as those needed for Session Replay, Surveys or Site Apps.
     *
     * @default false
     */
    disable_external_dependency_loading: boolean;
    /**
     * A function to be called when a script is being loaded.
     * This can be used to modify the script before it is loaded.
     * This is useful for adding a nonce to the script, for example.
     *
     * @param script - The script element that is being loaded.
     * @returns The modified script element, or null if the script should not be loaded.
     */
    prepare_external_dependency_script?: (script: HTMLScriptElement) => HTMLScriptElement | null;
    /**
     * A function to be called when a stylesheet is being loaded.
     * This can be used to modify the stylesheet before it is loaded.
     * This is useful for adding a nonce to the stylesheet, for example.
     *
     * @param stylesheet - The stylesheet element that is being loaded.
     * @returns The modified stylesheet element, or null if the stylesheet should not be loaded.
     */
    prepare_external_dependency_stylesheet?: (stylesheet: HTMLStyleElement) => HTMLStyleElement | null;
    /**
     * Determines whether PostHog should enable recording console logs.
     * When undefined, it falls back to the remote config setting.
     *
     * @default undefined
     */
    enable_recording_console_log?: boolean;
    /**
     * Determines whether PostHog should use secure cookies.
     * If this is `true`, PostHog cookies will be marked as secure,
     * meaning they will only be transmitted over HTTPS.
     *
     * @default window.location.protocol === 'https:'
     */
    secure_cookie: boolean;
    /**
     * Determines if users should be opted out of PostHog tracking by default,
     * requiring additional logic to opt them into capturing by calling `posthog.opt_in_capturing()`.
     *
     * @default false
     */
    opt_out_capturing_by_default: boolean;
    /**
     * Determines where we'll save the information about whether users are opted out of capturing.
     *
     * @default 'localStorage'
     */
    opt_out_capturing_persistence_type: 'localStorage' | 'cookie';
    /**
     * Determines if users should be opted out of browser data storage by this PostHog instance by default,
     * requiring additional logic to opt them into capturing by calling `posthog.opt_in_capturing()`.
     *
     * @default false
     */
    opt_out_persistence_by_default?: boolean;
    /**
     * Determines if users should be opted out of user agent filtering such as googlebot or other bots.
     * If this is set to `true`, PostHog will set `$browser_type` to either `bot` or `browser` for all events,
     * but will process all events as if they were from a browser.
     *
     * @default false
     */
    opt_out_useragent_filter: boolean;
    /** @deprecated Use `consent_persistence_name` instead. This will be removed in a future major version. **/
    opt_out_capturing_cookie_prefix: string | null;
    /**
     * Determines the key for the cookie / local storage used to store the information about whether users are opted in/out of capturing.
     * When `null`, we used a key based on your token.
     *
     * @default null
     * @see `ConsentManager._storageKey`
     */
    consent_persistence_name: string | null;
    /**
     * Determines if users should be opted in to site apps.
     *
     * @default false
     */
    opt_in_site_apps: boolean;
    /**
     * Determines whether PostHog should respect the Do Not Track header when computing
     * consent in `ConsentManager`.
     *
     * @see `ConsentManager`
     * @default false
     */
    respect_dnt: boolean;
    /**
     * A list of properties that should never be sent with capture calls.
     *
     * @default []
     */
    property_denylist: string[];
    /** @deprecated - use `property_denylist` instead  */
    property_blacklist?: string[];
    /**
     * A list of headers that should be sent with requests to the PostHog API.
     *
     * @default {}
     */
    request_headers: {
        [header_name: string]: string;
    };
    /** @deprecated - use `request_headers` instead  */
    xhr_headers?: {
        [header_name: string]: string;
    };
    /**
     * A function that is called when a request to the PostHog API fails.
     *
     * @param error - The `RequestResponse` object that occurred.
     */
    on_request_error?: (error: RequestResponse) => void;
    /** @deprecated - use `on_request_error` instead  */
    on_xhr_error?: (failedRequest: XMLHttpRequest) => void;
    /**
     * Determines whether PostHog should batch requests to the PostHog API.
     *
     * @default true
     */
    request_batching: boolean;
    /**
     * Determines the maximum length of the properties string that can be sent with capture calls.
     *
     * @default 65535
     */
    properties_string_max_length: number;
    /**
     * Configuration defaults for breaking changes. When set to a specific date,
     * enables new default behaviors that were introduced on that date.
     *
     * - `'unset'`: Use legacy default behaviors
     * - `'2025-05-24'`: Use updated default behaviors (e.g. capture_pageview defaults to 'history_change')
     *
     * @default 'unset'
     */
    defaults: ConfigDefaults;
    /**
     * Determines the session recording options.
     *
     * @see `SessionRecordingOptions`
     * @default {}
     */
    session_recording: SessionRecordingOptions;
    /**
     * Determines the error tracking options.
     *
     * @see `ErrorTrackingOptions`
     * @default {}
     */
    error_tracking: ErrorTrackingOptions;
    /**
     * Determines the session idle timeout in seconds.
     * Any new event that's happened after this timeout will create a new session.
     *
     * @default 30 * 60 -- 30 minutes
     */
    session_idle_timeout_seconds: number;
    /**
     * Prevent autocapture from capturing any attribute names on elements.
     *
     * @default false
     */
    mask_all_element_attributes: boolean;
    /**
     * Prevent autocapture from capturing `textContent` on elements.
     *
     * @default false
     */
    mask_all_text: boolean;
    /**
     * Mask personal data properties from the current URL.
     * This will mask personal data properties such as advertising IDs (gclid, fbclid, etc.), and you can also add
     * custom properties to mask with `custom_personal_data_properties`.
     * @default false
     * @see {PERSONAL_DATA_CAMPAIGN_PARAMS} - Default campaign parameters that are masked by default.
     * @see {PostHogConfig.custom_personal_data_properties} - Custom list of personal data properties to mask.
     */
    mask_personal_data_properties: boolean;
    /**
     * Custom list of personal data properties to mask.
     *
     * E.g. if you added `email` to this list, then any `email` property in the URL will be masked.
     * https://www.example.com/login?email=john.doe%40example.com => https://www.example.com/login?email=<MASKED>
     *
     * @default []
     * @see {PostHogConfig.mask_personal_data_properties} - Must be enabled for this to take effect.
     */
    custom_personal_data_properties: string[];
    /**
     * One of the very first things the PostHog library does when init() is called
     * is make a request to the /flags endpoint on PostHog's backend.
     * This endpoint contains information on how to run the PostHog library
     * so events are properly received in the backend, and it also contains
     * feature flag evaluation information for the current user.
     *
     * This endpoint is required to run most features of this library.
     * However, if you're not using any of the described features,
     * you may wish to turn off the call completely to avoid an extra request
     * and reduce resource usage on both the client and the server.
     *
     * @default false
     */
    advanced_disable_flags?: boolean;
    /**
     * @deprecated Use `advanced_disable_flags` instead. This will be removed in a future major version.
     *
     * One of the very first things the PostHog library does when init() is called
     * is make a request to the /decide endpoint on PostHog's backend.
     * This endpoint contains information on how to run the PostHog library
     * so events are properly received in the backend.
     *
     * This endpoint is required to run most features of the library.
     * However, if you're not using any of the described features,
     * you may wish to turn off the call completely to avoid an extra request
     * and reduce resource usage on both the client and the server.
     *
     * @default false
     */
    advanced_disable_decide?: boolean;
    /**
     * Will keep /flags running, but without evaluating any feature flags.
     * Useful for when you need to load the config data associated with the flags endpoint
     * (e.g. /flags?v=2&config=true) without evaluating any feature flags.  Most folks use this
     * to save money on feature flag evaluation (by bootstrapping feature flags on the server side).
     *
     * @default false
     */
    advanced_disable_feature_flags: boolean;
    /**
     * Stops from firing feature flag requests on first page load.
     * Only requests feature flags when user identity or properties are updated,
     * or you manually request for flags to be loaded.
     *
     * @default false
     */
    advanced_disable_feature_flags_on_first_load: boolean;
    /**
     * Determines whether PostHog should disable toolbar metrics.
     * This is our internal instrumentation for our toolbar in your website.
     *
     * @default false
     */
    advanced_disable_toolbar_metrics: boolean;
    /**
     * Determines whether PostHog should only evaluate feature flags for surveys.
     * Useful for when you want to use this library to evaluate feature flags for surveys only but you have additional feature flags
     * that you evaluate on the server side.
     *
     * @default false
     */
    advanced_only_evaluate_survey_feature_flags: boolean;
    /**
     * When this is enabled, surveys will always be initialized, regardless of the /flags response or remote config settings.
     * This is useful if you want to use surveys but disable all other flag-dependent functionality.
     * Used internally for displaying external surveys without making a /flags request.
     *
     * @default false
     */
    advanced_enable_surveys: boolean;
    /**
     * Sets timeout for fetching feature flags
     *
     * @default 3000
     */
    feature_flag_request_timeout_ms: number;
    /**
     * Sets timeout for fetching surveys
     *
     * @default 10000
     */
    surveys_request_timeout_ms: number;
    /**
     * Function to get the device ID.
     * This doesn't usually need to be set, but can be useful if you want to use a custom device ID.
     *
     * @param uuid - The UUID we would use for the device ID.
     * @returns The device ID.
     *
     * @default (uuid) => uuid
     */
    get_device_id: (uuid: string) => string;
    /**
     * This function or array of functions - if provided - are called immediately before sending data to the server.
     * It allows you to edit data before it is sent, or choose not to send it all.
     * if provided as an array the functions are called in the order they are provided
     * any one function returning null means the event will not be sent
     */
    before_send?: BeforeSendFn | BeforeSendFn[];
    /** @deprecated - use `before_send` instead */
    sanitize_properties: ((properties: Properties, event_name: string) => Properties) | null;
    /** @deprecated - use `before_send` instead */
    _onCapture: (eventName: string, eventData: CaptureResult) => void;
    /**
     * Determines whether to capture performance metrics.
     * These include Network Timing and Web Vitals.
     *
     * When `undefined`, fallback to the remote configuration.
     * If `false`, neither network timing nor web vitals will work.
     * If an object, that will override the remote configuration.
     *
     * @see {PerformanceCaptureConfig}
     * @default undefined
     */
    capture_performance?: boolean | PerformanceCaptureConfig;
    /**
     * Determines whether to disable compression when sending events to the server.
     * WARNING: Should only be used for testing. Could negatively impact performance.
     *
     * @default false
     */
    disable_compression: boolean;
    /**
     * An object containing the `distinctID`, `isIdentifiedID`, and `featureFlags` keys,
     * where `distinctID` is a string, and `featureFlags` is an object of key-value pairs.
     *
     * Since there is a delay between initializing PostHog and fetching feature flags,
     * feature flags are not always available immediately.
     * This makes them unusable if you want to do something like redirecting a user
     * to a different page based on a feature flag.
     *
     * You can, therefore, fetch the feature flags in your server and pre-fill them here,
     * allowing PostHog to know the feature flag values immediately.
     *
     * After the SDK fetches feature flags from PostHog, it will use those flag values instead of bootstrapped ones.
     *
     * @default {}
     */
    bootstrap: BootstrapConfig;
    /**
     * The segment analytics object.
     *
     * @see https://posthog.com/docs/libraries/segment
     */
    segment?: SegmentAnalytics;
    /**
     * Determines whether to capture heatmaps.
     *
     * @see {HeatmapConfig}
     * @default undefined
     */
    capture_heatmaps?: boolean | HeatmapConfig;
    enable_heatmaps?: boolean;
    /**
     * Determines whether to capture dead clicks.
     *
     * @see {DeadClicksAutoCaptureConfig}
     * @default undefined
     */
    capture_dead_clicks?: boolean | DeadClicksAutoCaptureConfig;
    /**
     * Determines whether to capture exceptions.
     *
     * @see {ExceptionAutoCaptureConfig}
     * @default undefined
     */
    capture_exceptions?: boolean | ExceptionAutoCaptureConfig;
    /**
     * Determines whether to disable scroll properties.
     * These allow you to keep track of how far down someone scrolled in your website.
     *
     * @default false
     */
    disable_scroll_properties?: boolean;
    /**
     * Let the pageview scroll stats use a custom css selector for the root element, e.g. `main`
     * It will use `window.document.documentElement` if not specified.
     */
    scroll_root_selector?: string | string[];
    /**
     * You can control whether events from PostHog-js have person processing enabled with the `person_profiles` config setting.
     * There are three options:
     * - `person_profiles: 'always'` - we will process persons data for all events
     * - `person_profiles: 'never'` - we won't process persons for any event. This means that anonymous users will not be merged once they sign up or login, so you lose the ability to create funnels that track users from anonymous to identified. All events (including `$identify`) will be sent with `$process_person_profile: False`.
     * - `person_profiles: 'identified_only'` _(default)_ - we will only process persons when you call `posthog.identify`, `posthog.alias`, `posthog.setPersonProperties`, `posthog.group`, `posthog.setPersonPropertiesForFlags` or `posthog.setGroupPropertiesForFlags` Anonymous users won't get person profiles.
     *
     * @default 'identified_only'
     */
    person_profiles?: 'always' | 'never' | 'identified_only';
    /** @deprecated - use `person_profiles` instead  */
    process_person?: 'always' | 'never' | 'identified_only';
    /**
     * Client side rate limiting
     */
    rate_limiting?: {
        /**
         * The average number of events per second that should be permitted
         *
         * @default 10
         */
        events_per_second?: number;
        /**
         * How many events can be captured in a burst. This defaults to 10 times the events_per_second count
         *
         * @default 10 * `events_per_second`
         */
        events_burst_limit?: number;
    };
    /**
     * Used when sending data via `fetch`, use with care.
     * This is intentionally meant to be used with NextJS `fetch`
     *
     * Incorrect `cache` usage may cause out-of-date data for feature flags, actions tracking, etc.
     * See https://nextjs.org/docs/app/api-reference/functions/fetch#fetchurl-options
     */
    fetch_options?: {
        cache?: RequestInit['cache'];
        next_options?: NextOptions;
    };
    /**
     * Used to change the behavior of the request queue.
     * This is an advanced feature and should be used with caution.
     */
    request_queue_config?: RequestQueueConfig;
    /**
     * Used to set-up external integrations with PostHog data - such as session replays, distinct id, etc.
     */
    integrations?: Record<ExternalIntegrationKind, boolean>;
    /**
     * Enables cookieless mode. In this mode, PostHog will not set any cookies, or use session or local storage. User
     * identity is handled by generating a privacy-preserving hash on PostHog's servers.
     * - 'always' - enable cookieless mode immediately on startup, use this if you do not intend to show a cookie banner
     * - 'on_reject' - enable cookieless mode only if the user rejects cookies, use this if you want to show a cookie banner. If the user accepts cookies, cookieless mode will not be used, and PostHog will use cookies and local storage as usual.
     *
     * Note that you MUST enable cookieless mode in your PostHog project's settings, otherwise all your cookieless events will be ignored. We plan to remove this requirement in the future.
     * */
    cookieless_mode?: 'always' | 'on_reject';
    /**
     * PREVIEW - MAY CHANGE WITHOUT WARNING - DO NOT USE IN PRODUCTION
     * A list of hostnames for which to inject PostHog tracing headers to all requests
     * (X-POSTHOG-DISTINCT-ID, X-POSTHOG-SESSION-ID, X-POSTHOG-WINDOW-ID)
     * */
    __add_tracing_headers?: string[];
    /**
     * PREVIEW - MAY CHANGE WITHOUT WARNING - DO NOT USE IN PRODUCTION
     * Enables the new RemoteConfig approach to loading config instead of /flags?v=2&config=true
     * */
    __preview_remote_config?: boolean;
    /**
     * PREVIEW - MAY CHANGE WITHOUT WARNING - DO NOT USE IN PRODUCTION
     * Whether to use the new /flags/ endpoint
     * */
    __preview_flags_v2?: boolean;
    /** @deprecated - NOT USED ANYMORE, kept here for backwards compatibility reasons */
    api_method?: string;
    /** @deprecated - NOT USED ANYMORE, kept here for backwards compatibility reasons */
    inapp_protocol?: string;
    /** @deprecated - NOT USED ANYMORE, kept here for backwards compatibility reasons */
    inapp_link_new_window?: boolean;
    /**
     * @deprecated - THIS OPTION HAS NO EFFECT, kept here for backwards compatibility reasons.
     * Use a custom transformation or "Discard IP data" project setting instead: @see https://posthog.com/tutorials/web-redact-properties#hiding-customer-ip-address.
     */
    ip: boolean;
}
interface ErrorTrackingOptions {
    /**
     * Decide whether exceptions thrown by browser extensions should be captured
     *
     * @default false
     */
    captureExtensionExceptions?: boolean;
    /**
     * ADVANCED: alters the refill rate for the token bucket mutation throttling
     * Normally only altered alongside posthog support guidance.
     * Accepts values between 0 and 100
     *
     * @default 1
     */
    __exceptionRateLimiterRefillRate?: number;
    /**
     * ADVANCED: alters the bucket size for the token bucket mutation throttling
     * Normally only altered alongside posthog support guidance.
     * Accepts values between 0 and 100
     *
     * @default 10
     */
    __exceptionRateLimiterBucketSize?: number;
}
interface SessionRecordingOptions {
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default 'ph-no-capture'
     */
    blockClass?: string | RegExp;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default null
     */
    blockSelector?: string | null;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default 'ph-ignore-input'
     */
    ignoreClass?: string | RegExp;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default 'ph-mask'
     */
    maskTextClass?: string | RegExp;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     */
    maskTextSelector?: string | null;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     */
    maskTextFn?: ((text: string, element?: HTMLElement) => string) | null;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     */
    maskAllInputs?: boolean;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     */
    maskInputOptions?: recordOptions['maskInputOptions'];
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     */
    maskInputFn?: ((text: string, element?: HTMLElement) => string) | null;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default {}
     */
    slimDOMOptions?: recordOptions['slimDOMOptions'];
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default false
     */
    collectFonts?: boolean;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default true
     */
    inlineStylesheet?: boolean;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default false
     */
    recordCrossOriginIframes?: boolean;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default false
     */
    recordHeaders?: boolean;
    /**
     * Derived from `rrweb.record` options
     * @see https://github.com/rrweb-io/rrweb/blob/master/guide.md
     * @default false
     */
    recordBody?: boolean;
    /**
     * Allows local config to override remote canvas recording settings from the flags response
     */
    captureCanvas?: SessionRecordingCanvasOptions;
    /**
     * Modify the network request before it is captured. Returning null or undefined stops it being captured
     */
    maskCapturedNetworkRequestFn?: ((data: CapturedNetworkRequest) => CapturedNetworkRequest | null | undefined) | null;
    /** @deprecated - use maskCapturedNetworkRequestFn instead  */
    maskNetworkRequestFn?: ((data: NetworkRequest) => NetworkRequest | null | undefined) | null;
    /**
     * ADVANCED: while a user is active we take a full snapshot of the browser every interval.
     * For very few sites playback performance might be better with different interval.
     * Set to 0 to disable
     *
     * @default 1000 * 60 * 5 (5 minutes)
     */
    full_snapshot_interval_millis?: number;
    /**
     * ADVANCED: whether to partially compress rrweb events before sending them to the server,
     * defaults to true, can be set to false to disable partial compression
     * NB requests are still compressed when sent to the server regardless of this setting
     *
     * @default true
     */
    compress_events?: boolean;
    /**
     * ADVANCED: alters the threshold before a recording considers a user has become idle.
     * Normally only altered alongside changes to session_idle_timeout_ms.
     *
     * @default 1000 * 60 * 5 (5 minutes)
     */
    session_idle_threshold_ms?: number;
    /**
     * ADVANCED: alters the refill rate for the token bucket mutation throttling
     * Normally only altered alongside posthog support guidance.
     * Accepts values between 0 and 100
     *
     * @default 10
     */
    __mutationThrottlerRefillRate?: number;
    /**
     * ADVANCED: alters the bucket size for the token bucket mutation throttling
     * Normally only altered alongside posthog support guidance.
     * Accepts values between 0 and 100
     *
     * @default 100
     */
    __mutationThrottlerBucketSize?: number;
}
type SessionIdChangedCallback = (sessionId: string, windowId: string | null | undefined, changeReason?: {
    noSessionId: boolean;
    activityTimeout: boolean;
    sessionPastMaximumLength: boolean;
}) => void;
declare enum Compression {
    GZipJS = "gzip-js",
    Base64 = "base64"
}
interface RequestResponse {
    statusCode: number;
    text?: string;
    json?: any;
}
type RequestCallback = (response: RequestResponse) => void;
type NextOptions = {
    revalidate: false | 0 | number;
    tags: string[];
};
interface RequestWithOptions {
    url: string;
    data?: Record<string, any> | Record<string, any>[];
    headers?: Record<string, any>;
    transport?: 'XHR' | 'fetch' | 'sendBeacon';
    method?: 'POST' | 'GET';
    urlQueryArgs?: {
        compression: Compression;
    };
    callback?: RequestCallback;
    timeout?: number;
    noRetries?: boolean;
    compression?: Compression | 'best-available';
    fetchOptions?: {
        cache?: RequestInit['cache'];
        next?: NextOptions;
    };
}
interface QueuedRequestWithOptions extends RequestWithOptions {
    /** key of queue, e.g. 'sessionRecording' vs 'event' */
    batchKey?: string;
}
interface RetriableRequestWithOptions extends QueuedRequestWithOptions {
    retriesPerformedSoFar?: number;
}
interface RequestQueueConfig {
    /**
     *  ADVANCED - alters the frequency which PostHog sends events to the server.
     *  generally speaking this is only set when apps have automatic page refreshes, or very short visits.
     *  Defaults to 3 seconds when not set
     *  Allowed values between 250 and 5000
     * */
    flush_interval_ms?: number;
}
interface CaptureOptions {
    /**
     * Used when `$identify` is called
     * Will set person properties overriding previous values
     */
    $set?: Properties;
    /**
     * Used when `$identify` is called
     * Will set person properties but only once, it will NOT override previous values
     */
    $set_once?: Properties;
    /**
     * Used to override the desired endpoint for the captured event
     */
    _url?: string;
    /**
     * key of queue, e.g. 'sessionRecording' vs 'event'
     */
    _batchKey?: string;
    /**
     * If set, overrides and disables config.properties_string_max_length
     */
    _noTruncate?: boolean;
    /**
     * If set, skips the batched queue
     */
    send_instantly?: boolean;
    /**
     * If set, skips the client side rate limiting
     */
    skip_client_rate_limiting?: boolean;
    /**
     * If set, overrides the desired transport method
     */
    transport?: RequestWithOptions['transport'];
    /**
     * If set, overrides the current timestamp
     */
    timestamp?: Date;
}
type FlagVariant = {
    flag: string;
    variant: string;
};
type SessionRecordingCanvasOptions = {
    /**
     * If set, records the canvas
     *
     * @default false
     */
    recordCanvas?: boolean | null;
    /**
     * If set, records the canvas at the given FPS
     * Can be set in the remote configuration
     * Limited between 0 and 12
     * When canvas recording is enabled, if this is not set locally, then remote config sets this as 4
     *
     * @default null-ish
     */
    canvasFps?: number | null;
    /**
     * If set, records the canvas at the given quality
     * Can be set in the remote configuration
     * Must be a string that is a valid decimal between 0 and 1
     * When canvas recording is enabled, if this is not set locally, then remote config sets this as "0.4"
     *
     * @default null-ish
     */
    canvasQuality?: string | null;
};
/**
 * Remote configuration for the PostHog instance
 *
 * All of these settings can be configured directly in your PostHog instance
 * Any configuration set in the client overrides the information from the server
 */
interface RemoteConfig {
    /**
     * Supported compression algorithms
     */
    supportedCompression: Compression[];
    /**
     * If set, disables autocapture
     */
    autocapture_opt_out?: boolean;
    /**
     *     originally capturePerformance was replay only and so boolean true
     *     is equivalent to { network_timing: true }
     *     now capture performance can be separately enabled within replay
     *     and as a standalone web vitals tracker
     *     people can have them enabled separately
     *     they work standalone but enhance each other
     *     TODO: deprecate this so we make a new config that doesn't need this explanation
     */
    capturePerformance?: boolean | PerformanceCaptureConfig;
    /**
     * Whether we should use a custom endpoint for analytics
     *
     * @default { endpoint: "/e" }
     */
    analytics?: {
        endpoint?: string;
    };
    /**
     * Whether the `$elements_chain` property should be sent as a string or as an array
     *
     * @default false
     */
    elementsChainAsString?: boolean;
    /**
     * Error tracking configuration options
     */
    errorTracking?: {
        autocaptureExceptions?: boolean;
        captureExtensionExceptions?: boolean;
        suppressionRules?: ErrorTrackingSuppressionRule[];
    };
    /**
     * This is currently in development and may have breaking changes without a major version bump
     */
    autocaptureExceptions?: boolean | {
        endpoint?: string;
    };
    /**
     * Session recording configuration options
     */
    sessionRecording?: SessionRecordingCanvasOptions & {
        endpoint?: string;
        consoleLogRecordingEnabled?: boolean;
        sampleRate?: string | null;
        minimumDurationMilliseconds?: number;
        linkedFlag?: string | FlagVariant | null;
        networkPayloadCapture?: Pick<NetworkRecordOptions, 'recordBody' | 'recordHeaders'>;
        masking?: Pick<SessionRecordingOptions, 'maskAllInputs' | 'maskTextSelector'>;
        urlTriggers?: SessionRecordingUrlTrigger[];
        scriptConfig?: {
            script?: string | undefined;
        };
        urlBlocklist?: SessionRecordingUrlTrigger[];
        eventTriggers?: string[];
        /**
         * Controls how event, url, sampling, and linked flag triggers are combined
         *
         * `any` means that if any of the triggers match, the session will be recorded
         * `all` means that all the triggers must match for the session to be recorded
         *
         * originally it was (event || url) && (sampling || linked flag)
         * which nobody wanted, now the default is all
         */
        triggerMatchType?: 'any' | 'all';
    };
    /**
     * Whether surveys are enabled
     */
    surveys?: boolean | Survey[];
    /**
     * Parameters for the toolbar
     */
    toolbarParams: ToolbarParams;
    /**
     * @deprecated renamed to toolbarParams, still present on older API responses
     */
    editorParams?: ToolbarParams;
    /**
     * @deprecated, moved to toolbarParams
     */
    toolbarVersion: 'toolbar';
    /**
     * Whether the user is authenticated
     */
    isAuthenticated: boolean;
    /**
     * List of site apps with their IDs and URLs
     */
    siteApps: {
        id: string;
        url: string;
    }[];
    /**
     * Whether heatmaps are enabled
     */
    heatmaps?: boolean;
    /**
     * Whether to only capture identified users by default
     */
    defaultIdentifiedOnly?: boolean;
    /**
     * Whether to capture dead clicks
     */
    captureDeadClicks?: boolean;
    /**
     * Indicates if the team has any flags enabled (if not we don't need to load them)
     */
    hasFeatureFlags?: boolean;
}
/**
 * Flags returns feature flags and their payloads, and optionally returns everything else from the remote config
 * assuming it's called with `config=true`
 */
interface FlagsResponse extends RemoteConfig {
    featureFlags: Record<string, string | boolean>;
    featureFlagPayloads: Record<string, JsonType>;
    errorsWhileComputingFlags: boolean;
    requestId?: string;
    flags: Record<string, FeatureFlagDetail>;
}
type SiteAppGlobals = {
    event: {
        uuid: string;
        event: EventName;
        properties: Properties;
        timestamp?: Date;
        elements_chain?: string;
        distinct_id?: string;
    };
    person: {
        properties: Properties;
    };
    groups: Record<string, {
        id: string;
        type: string;
        properties: Properties;
    }>;
};
type SiteAppLoader = {
    id: string;
    init: (config: {
        posthog: PostHog;
        callback: (success: boolean) => void;
    }) => {
        processEvent?: (globals: SiteAppGlobals) => void;
    };
};
type SiteApp = {
    id: string;
    loaded: boolean;
    errored: boolean;
    processedBuffer: boolean;
    processEvent?: (globals: SiteAppGlobals) => void;
};
type FeatureFlagsCallback = (flags: string[], variants: Record<string, string | boolean>, context?: {
    errorsLoading?: boolean;
}) => void;
type FeatureFlagDetail = {
    key: string;
    enabled: boolean;
    original_enabled?: boolean | undefined;
    variant: string | undefined;
    original_variant?: string | undefined;
    reason: EvaluationReason | undefined;
    metadata: FeatureFlagMetadata | undefined;
};
type FeatureFlagMetadata = {
    id: number;
    version: number | undefined;
    description: string | undefined;
    payload: JsonType | undefined;
    original_payload?: JsonType | undefined;
};
type EvaluationReason = {
    code: string;
    condition_index: number | undefined;
    description: string | undefined;
};
type RemoteConfigFeatureFlagCallback = (payload: JsonType) => void;
interface PersistentStore {
    _is_supported: () => boolean;
    _error: (error: any) => void;
    _parse: (name: string) => any;
    _get: (name: string) => any;
    _set: (name: string, value: any, expire_days?: number | null, cross_subdomain?: boolean, secure?: boolean, debug?: boolean) => void;
    _remove: (name: string, cross_subdomain?: boolean) => void;
}
type Breaker = {};
type EventHandler = (event: Event) => boolean | void;
type ToolbarUserIntent = 'add-action' | 'edit-action';
type ToolbarSource = 'url' | 'localstorage';
type ToolbarVersion = 'toolbar';
interface ToolbarParams {
    token?: string; /** public posthog-js token */
    temporaryToken?: string; /** private temporary user token */
    actionId?: number;
    userIntent?: ToolbarUserIntent;
    source?: ToolbarSource;
    toolbarVersion?: ToolbarVersion;
    instrument?: boolean;
    distinctId?: string;
    userEmail?: string;
    dataAttributes?: string[];
    featureFlags?: Record<string, string | boolean>;
}
type SnippetArrayItem = [method: string, ...args: any[]];
type JsonRecord = {
    [key: string]: JsonType;
};
type JsonType = string | number | boolean | null | undefined | JsonRecord | Array<JsonType>;
/** A feature that isn't publicly available yet.*/
interface EarlyAccessFeature {
    name: string;
    description: string;
    stage: 'concept' | 'alpha' | 'beta';
    documentationUrl: string | null;
    flagKey: string | null;
}
type EarlyAccessFeatureStage = 'concept' | 'alpha' | 'beta' | 'general-availability';
type EarlyAccessFeatureCallback = (earlyAccessFeatures: EarlyAccessFeature[]) => void;
interface EarlyAccessFeatureResponse {
    earlyAccessFeatures: EarlyAccessFeature[];
}
type Headers = Record<string, string>;
type InitiatorType = 'audio' | 'beacon' | 'body' | 'css' | 'early-hint' | 'embed' | 'fetch' | 'frame' | 'iframe' | 'icon' | 'image' | 'img' | 'input' | 'link' | 'navigation' | 'object' | 'ping' | 'script' | 'track' | 'video' | 'xmlhttprequest';
type NetworkRecordOptions = {
    initiatorTypes?: InitiatorType[];
    maskRequestFn?: (data: CapturedNetworkRequest) => CapturedNetworkRequest | undefined;
    recordHeaders?: boolean | {
        request: boolean;
        response: boolean;
    };
    recordBody?: boolean | string[] | {
        request: boolean | string[];
        response: boolean | string[];
    };
    recordInitialRequests?: boolean;
    /**
     * whether to record PerformanceEntry events for network requests
     */
    recordPerformance?: boolean;
    /**
     * the PerformanceObserver will only observe these entry types
     */
    performanceEntryTypeToObserve: string[];
    /**
     * the maximum size of the request/response body to record
     * NB this will be at most 1MB even if set larger
     */
    payloadSizeLimitBytes: number;
    /**
     * some domains we should never record the payload
     * for example other companies session replay ingestion payloads aren't super useful but are gigantic
     * if this isn't provided we use a default list
     * if this is provided - we add the provided list to the default list
     * i.e. we never record the payloads on the default deny list
     */
    payloadHostDenyList?: string[];
};
/** @deprecated - use CapturedNetworkRequest instead  */
type NetworkRequest = {
    url: string;
};
type Writable<T> = {
    -readonly [P in keyof T]: T[P];
};
type CapturedNetworkRequest = Writable<Omit<PerformanceEntry, 'toJSON'>> & {
    method?: string;
    initiatorType?: InitiatorType;
    status?: number;
    timeOrigin?: number;
    timestamp?: number;
    startTime?: number;
    endTime?: number;
    requestHeaders?: Headers;
    requestBody?: string | null;
    responseHeaders?: Headers;
    responseBody?: string | null;
    isInitial?: boolean;
};
type ErrorEventArgs = [
    event: string | Event,
    source?: string | undefined,
    lineno?: number | undefined,
    colno?: number | undefined,
    error?: Error | undefined
];
declare const severityLevels: readonly ["fatal", "error", "warning", "log", "info", "debug"];
declare type SeverityLevel = (typeof severityLevels)[number];
interface SessionRecordingUrlTrigger {
    url: string;
    matching: 'regex';
}
type PropertyMatchType = 'regex' | 'not_regex' | 'exact' | 'is_not' | 'icontains' | 'not_icontains';
interface ErrorTrackingSuppressionRule {
    type: 'AND' | 'OR';
    values: ErrorTrackingSuppressionRuleValue[];
}
interface ErrorTrackingSuppressionRuleValue {
    key: '$exception_types' | '$exception_values';
    operator: PropertyMatchType;
    value: string | string[];
    type: string;
}

declare class Autocapture {
    instance: PostHog;
    _initialized: boolean;
    _isDisabledServerSide: boolean | null;
    _elementSelectors: Set<string> | null;
    rageclicks: RageClick;
    _elementsChainAsString: boolean;
    constructor(instance: PostHog);
    private get _config();
    _addDomEventHandlers(): void;
    startIfEnabled(): void;
    onRemoteConfig(response: RemoteConfig): void;
    setElementSelectors(selectors: Set<string>): void;
    getElementSelectors(element: Element | null): string[] | null;
    get isEnabled(): boolean;
    private _captureEvent;
    isBrowserSupported(): boolean;
}

declare enum ConsentStatus {
    PENDING = -1,
    DENIED = 0,
    GRANTED = 1
}
/**
 * ConsentManager provides tools for managing user consent as configured by the application.
 */
declare class ConsentManager {
    private _instance;
    private _persistentStore?;
    constructor(_instance: PostHog);
    private get _config();
    get consent(): ConsentStatus;
    isOptedOut(): boolean;
    isOptedIn(): boolean;
    isExplicitlyOptedOut(): boolean;
    optInOut(isOptedIn: boolean): void;
    reset(): void;
    private get _storageKey();
    private get _storedConsent();
    private get _storage();
    private _getDnt;
}

interface StackFrame {
    platform: string;
    filename?: string;
    function?: string;
    module?: string;
    lineno?: number;
    colno?: number;
    abs_path?: string;
    context_line?: string;
    pre_context?: string[];
    post_context?: string[];
    in_app?: boolean;
    instruction_addr?: string;
    addr_mode?: string;
    vars?: {
        [key: string]: any;
    };
    chunk_id?: string;
}

interface ErrorProperties {
    $exception_list: Exception[];
    $exception_level?: SeverityLevel;
    $exception_DOMException_code?: string;
    $exception_personURL?: string;
}
interface Exception {
    type?: string;
    value?: string;
    mechanism?: {
        /**
         * In theory, whether or not the exception has been handled by the user. In practice, whether or not we see it before
         * it hits the global error/rejection handlers, whether through explicit handling by the user or auto instrumentation.
         */
        handled?: boolean;
        type?: string;
        source?: string;
        /**
         * True when `captureException` is called with anything other than an instance of `Error` (or, in the case of browser,
         * an instance of `ErrorEvent`, `DOMError`, or `DOMException`). causing us to create a synthetic error in an attempt
         * to recreate the stacktrace.
         */
        synthetic?: boolean;
    };
    module?: string;
    thread_id?: number;
    stacktrace?: {
        frames?: StackFrame[];
        type: 'raw';
    };
}

declare class SessionIdManager {
    private readonly _sessionIdGenerator;
    private readonly _windowIdGenerator;
    private _config;
    private _persistence;
    private _windowId;
    private _sessionId;
    private readonly _window_id_storage_key;
    private readonly _primary_window_exists_storage_key;
    private _sessionStartTimestamp;
    private _sessionActivityTimestamp;
    private _sessionIdChangedHandlers;
    private readonly _sessionTimeoutMs;
    private _enforceIdleTimeout;
    constructor(instance: PostHog, sessionIdGenerator?: () => string, windowIdGenerator?: () => string);
    get sessionTimeoutMs(): number;
    onSessionId(callback: SessionIdChangedCallback): () => void;
    private _canUseSessionStorage;
    private _setWindowId;
    private _getWindowId;
    private _setSessionId;
    private _getSessionId;
    resetSessionId(): void;
    private _listenToReloadWindow;
    private _sessionHasBeenIdleTooLong;
    checkAndGetSessionAndWindowId(readOnly?: boolean, _timestamp?: number | null): {
        sessionId: string;
        windowId: string;
        sessionStartTimestamp: number;
        changeReason: {
            noSessionId: boolean;
            activityTimeout: boolean;
            sessionPastMaximumLength: boolean;
        } | undefined;
        lastActivityTimestamp: number;
    };
    private _resetIdleTimer;
}

interface LazyLoadedDeadClicksAutocaptureInterface {
    start: (observerTarget: Node) => void;
    stop: () => void;
}

declare class DeadClicksAutocapture {
    readonly instance: PostHog;
    readonly isEnabled: (dca: DeadClicksAutocapture) => boolean;
    readonly onCapture?: DeadClicksAutoCaptureConfig['__onCapture'];
    get lazyLoadedDeadClicksAutocapture(): LazyLoadedDeadClicksAutocaptureInterface | undefined;
    private _lazyLoadedDeadClicksAutocapture;
    constructor(instance: PostHog, isEnabled: (dca: DeadClicksAutocapture) => boolean, onCapture?: DeadClicksAutoCaptureConfig['__onCapture']);
    onRemoteConfig(response: RemoteConfig): void;
    startIfEnabled(): void;
    private _loadScript;
    private _start;
    stop(): void;
}

declare class ExceptionObserver {
    private _instance;
    private _rateLimiter;
    private _remoteEnabled;
    private _config;
    private _unwrapOnError;
    private _unwrapUnhandledRejection;
    private _unwrapConsoleError;
    constructor(instance: PostHog);
    private _requiredConfig;
    get isEnabled(): boolean;
    startIfEnabled(): void;
    private _loadScript;
    private _startCapturing;
    private _stopCapturing;
    onRemoteConfig(response: RemoteConfig): void;
    captureException(errorProperties: ErrorProperties): void;
}

/**
 * This class is used to capture pageview events when the user navigates using the history API (pushState, replaceState)
 * and when the user navigates using the browser's back/forward buttons.
 *
 * The behavior is controlled by the `capture_pageview` configuration option:
 * - When set to `'history_change'`, this class will capture pageviews on history API changes
 */
declare class HistoryAutocapture {
    private _instance;
    private _popstateListener;
    private _lastPathname;
    constructor(instance: PostHog);
    get isEnabled(): boolean;
    startIfEnabled(): void;
    stop(): void;
    monitorHistoryChanges(): void;
    private _capturePageview;
    private _setupPopstateListener;
}

declare const SAMPLED = "sampled";
type TriggerType = 'url' | 'event';
/**
 * Session recording starts in buffering mode while waiting for "flags response".
 * Once the response is received, it might be disabled, active or sampled.
 * When "sampled" that means a sample rate is set, and the last time the session ID rotated
 * the sample rate determined this session should be sent to the server.
 */
declare const sessionRecordingStatuses: readonly ["disabled", "sampled", "active", "buffering", "paused"];
type SessionRecordingStatus = (typeof sessionRecordingStatuses)[number];

type SessionStartReason = 'sampling_overridden' | 'recording_initialized' | 'linked_flag_matched' | 'linked_flag_overridden' | typeof SAMPLED | 'session_id_changed' | 'url_trigger_matched' | 'event_trigger_matched';
declare class SessionRecording {
    private readonly _instance;
    private _endpoint;
    private _flushBufferTimer?;
    private _statusMatcher;
    private _receivedFlags;
    private _buffer;
    private _queuedRRWebEvents;
    private _mutationThrottler?;
    private _captureStarted;
    private _stopRrweb;
    private _isIdle;
    private _lastActivityTimestamp;
    private _windowId;
    private _sessionId;
    get sessionId(): string;
    private _linkedFlagMatching;
    private _urlTriggerMatching;
    private _eventTriggerMatching;
    private _triggerMatching;
    private _fullSnapshotTimer?;
    private _removePageViewCaptureHook;
    private _onSessionIdListener;
    private _persistFlagsOnSessionListener;
    private _samplingSessionListener;
    private _lastHref?;
    private _removeEventTriggerCaptureHook;
    _forceAllowLocalhostNetworkCapture: boolean;
    private get _sessionIdleThresholdMilliseconds();
    get started(): boolean;
    private get _sessionManager();
    private get _fullSnapshotIntervalMillis();
    private get _isSampled();
    private get _sessionDuration();
    private get _isRecordingEnabled();
    private get _isConsoleLogCaptureEnabled();
    private get _canvasRecording();
    private get _networkPayloadCapture();
    private get _masking();
    private get _sampleRate();
    private get _minimumDuration();
    /**
     * defaults to buffering mode until a flags response is received
     * once a flags response is received status can be disabled, active or sampled
     */
    get status(): SessionRecordingStatus;
    constructor(_instance: PostHog);
    private _onBeforeUnload;
    private _onOffline;
    private _onOnline;
    private _onVisibilityChange;
    startIfEnabledOrStop(startReason?: SessionStartReason): void;
    stopRecording(): void;
    private _resetSampling;
    private _makeSamplingDecision;
    onRemoteConfig(response: RemoteConfig): void;
    /**
     * This might be called more than once so needs to be idempotent
     */
    private _setupSampling;
    private _persistRemoteConfig;
    log(message: string, level?: 'log' | 'warn' | 'error'): void;
    private _startCapture;
    private get _scriptName();
    private _isInteractiveEvent;
    private _updateWindowAndSessionIds;
    private _tryRRWebMethod;
    private _tryAddCustomEvent;
    private _tryTakeFullSnapshot;
    private _onScriptLoaded;
    private _scheduleFullSnapshot;
    private _gatherRRWebPlugins;
    onRRwebEmit(rawEvent: eventWithTime): void;
    private _pageViewFallBack;
    private _processQueuedEvents;
    private _maskUrl;
    private _clearBuffer;
    private _flushBuffer;
    private _captureSnapshotBuffered;
    private _captureSnapshot;
    private _activateTrigger;
    private _pauseRecording;
    private _resumeRecording;
    private _addEventTriggerListener;
    /**
     * this ignores the linked flag config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({linked_flag: true})`
     * */
    overrideLinkedFlag(): void;
    /**
     * this ignores the sampling config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({sampling: true})`
     * */
    overrideSampling(): void;
    /**
     * this ignores the URL/Event trigger config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({trigger: 'url' | 'event'})`
     * */
    overrideTrigger(triggerType: TriggerType): void;
    private _reportStarted;
    get sdkDebugProperties(): Properties;
}

/**
 * Integrate Sentry with PostHog. This will add a direct link to the person in Sentry, and an $exception event in PostHog
 *
 * ### Usage
 *
 *     Sentry.init({
 *          dsn: 'https://example',
 *          integrations: [
 *              new posthog.SentryIntegration(posthog)
 *          ]
 *     })
 *
 * @param {Object} [posthog] The posthog object
 * @param {string} [organization] Optional: The Sentry organization, used to send a direct link from PostHog to Sentry
 * @param {Number} [projectId] Optional: The Sentry project id, used to send a direct link from PostHog to Sentry
 * @param {string} [prefix] Optional: Url of a self-hosted sentry instance (default: https://sentry.io/organizations/)
 * @param {SeverityLevel[] | '*'} [severityAllowList] Optional: send events matching the provided levels. Use '*' to send all events (default: ['error'])
 */

type _SentryEvent = any;
type _SentryEventProcessor = any;
type _SentryHub = any;
interface _SentryIntegration {
    name: string;
    processEvent(event: _SentryEvent): _SentryEvent;
}
interface _SentryIntegrationClass {
    name: string;
    setupOnce(addGlobalEventProcessor: (callback: _SentryEventProcessor) => void, getCurrentHub: () => _SentryHub): void;
}
type SentryIntegrationOptions = {
    organization?: string;
    projectId?: number;
    prefix?: string;
    severityAllowList?: SeverityLevel[] | '*';
};
declare function sentryIntegration(_posthog: PostHog, options?: SentryIntegrationOptions): _SentryIntegration;
declare class SentryIntegration implements _SentryIntegrationClass {
    name: string;
    setupOnce: (addGlobalEventProcessor: (callback: _SentryEventProcessor) => void, getCurrentHub: () => _SentryHub) => void;
    constructor(_posthog: PostHog, organization?: string, projectId?: number, prefix?: string, severityAllowList?: SeverityLevel[] | '*');
}

declare class Toolbar {
    instance: PostHog;
    constructor(instance: PostHog);
    private _setToolbarState;
    private _getToolbarState;
    /**
     * To load the toolbar, we need an access token and other state. That state comes from one of three places:
     * 1. In the URL hash params
     * 2. From session storage under the key `toolbarParams` if the toolbar was initialized on a previous page
     */
    maybeLoadToolbar(location?: Location | undefined, localStorage?: Storage | undefined, history?: History | undefined): boolean;
    private _callLoadToolbar;
    loadToolbar(params?: ToolbarParams): boolean;
    /** @deprecated Use "loadToolbar" instead. */
    _loadEditor(params: ToolbarParams): boolean;
    /** @deprecated Use "maybeLoadToolbar" instead. */
    maybeLoadEditor(location?: Location | undefined, localStorage?: Storage | undefined, history?: History | undefined): boolean;
}

declare class WebVitalsAutocapture {
    private readonly _instance;
    private _enabledServerSide;
    private _initialized;
    private _buffer;
    private _delayedFlushTimer;
    constructor(_instance: PostHog);
    get allowedMetrics(): SupportedWebVitalsMetrics[];
    get flushToCaptureTimeoutMs(): number;
    get _maxAllowedValue(): number;
    get isEnabled(): boolean;
    startIfEnabled(): void;
    onRemoteConfig(response: RemoteConfig): void;
    private _loadScript;
    private _currentURL;
    private _flushToCapture;
    private _addToBuffer;
    private _startCapturing;
}

type HeatmapEventBuffer = {
    [key: string]: Properties[];
} | undefined;
declare class Heatmaps {
    instance: PostHog;
    rageclicks: RageClick;
    _enabledServerSide: boolean;
    _initialized: boolean;
    _mouseMoveTimeout: ReturnType<typeof setTimeout> | undefined;
    private _buffer;
    private _flushInterval;
    private _deadClicksCapture;
    constructor(instance: PostHog);
    get flushIntervalMilliseconds(): number;
    get isEnabled(): boolean;
    startIfEnabled(): void;
    onRemoteConfig(response: RemoteConfig): void;
    getAndClearBuffer(): HeatmapEventBuffer;
    private _onDeadClick;
    private _setupListeners;
    private _getProperties;
    private _onClick;
    private _onMouseMove;
    private _capture;
    private _flush;
}

interface PageViewEventProperties {
    $pageview_id?: string;
    $prev_pageview_id?: string;
    $prev_pageview_pathname?: string;
    $prev_pageview_duration?: number;
    $prev_pageview_last_scroll?: number;
    $prev_pageview_last_scroll_percentage?: number;
    $prev_pageview_max_scroll?: number;
    $prev_pageview_max_scroll_percentage?: number;
    $prev_pageview_last_content?: number;
    $prev_pageview_last_content_percentage?: number;
    $prev_pageview_max_content?: number;
    $prev_pageview_max_content_percentage?: number;
}
declare class PageViewManager {
    _currentPageview?: {
        timestamp: Date;
        pageViewId: string | undefined;
        pathname: string | undefined;
    };
    _instance: PostHog;
    constructor(instance: PostHog);
    doPageView(timestamp: Date, pageViewId?: string): PageViewEventProperties;
    doPageLeave(timestamp: Date): PageViewEventProperties;
    doEvent(): PageViewEventProperties;
    private _previousPageViewProperties;
}

declare class PostHogExceptions {
    private readonly _instance;
    private _suppressionRules;
    constructor(instance: PostHog);
    onRemoteConfig(response: RemoteConfig): void;
    private get _captureExtensionExceptions();
    sendExceptionEvent(properties: Properties): CaptureResult | undefined;
    private _matchesSuppressionRule;
    private _isExtensionException;
}

/**
 * PostHog Persistence Object
 * @constructor
 */
declare class PostHogPersistence {
    private _config;
    props: Properties;
    private _storage;
    private _campaign_params_saved;
    private readonly _name;
    _disabled: boolean | undefined;
    private _secure;
    private _expire_days;
    private _default_expiry;
    private _cross_subdomain;
    /**
     * @param {PostHogConfig} config initial PostHog configuration
     * @param {boolean=} isDisabled should persistence be disabled (e.g. because of consent management)
     */
    constructor(config: PostHogConfig, isDisabled?: boolean);
    isDisabled(): boolean;
    private _buildStorage;
    properties(): Properties;
    load(): void;
    /**
     * NOTE: Saving frequently causes issues with Recordings and Consent Management Platform (CMP) tools which
     * observe cookie changes, and modify their UI, often causing infinite loops.
     * As such callers of this should ideally check that the data has changed beforehand
     */
    save(): void;
    remove(): void;
    clear(): void;
    /**
     * @param {Object} props
     * @param {*=} default_value
     * @param {number=} days
     */
    register_once(props: Properties, default_value: any, days?: number): boolean;
    /**
     * @param {Object} props
     * @param {number=} days
     */
    register(props: Properties, days?: number): boolean;
    unregister(prop: string): void;
    update_campaign_params(): void;
    update_search_keyword(): void;
    update_referrer_info(): void;
    set_initial_person_info(): void;
    get_initial_props(): Properties;
    safe_merge(props: Properties): Properties;
    update_config(config: PostHogConfig, oldConfig: PostHogConfig, isDisabled?: boolean): void;
    set_disabled(disabled: boolean): void;
    set_cross_subdomain(cross_subdomain: boolean): void;
    set_secure(secure: boolean): void;
    set_event_timer(event_name: string, timestamp: number): void;
    remove_event_timer(event_name: string): number;
    get_property(prop: string): any;
    set_property(prop: string, to: any): void;
}

type FeatureFlagOverrides = {
    [flagName: string]: string | boolean;
};
type FeatureFlagPayloadOverrides = {
    [flagName: string]: JsonType;
};
type FeatureFlagOverrideOptions = {
    flags?: boolean | string[] | FeatureFlagOverrides;
    payloads?: FeatureFlagPayloadOverrides;
    suppressWarning?: boolean;
};
type OverrideFeatureFlagsOptions = boolean | string[] | FeatureFlagOverrides | FeatureFlagOverrideOptions;
declare class PostHogFeatureFlags {
    private _instance;
    _override_warning: boolean;
    featureFlagEventHandlers: FeatureFlagsCallback[];
    $anon_distinct_id: string | undefined;
    private _hasLoadedFlags;
    private _requestInFlight;
    private _reloadingDisabled;
    private _additionalReloadRequested;
    private _reloadDebouncer?;
    private _flagsCalled;
    private _flagsLoadedFromRemote;
    constructor(_instance: PostHog);
    flags(): void;
    get hasLoadedFlags(): boolean;
    getFlags(): string[];
    getFlagsWithDetails(): Record<string, FeatureFlagDetail>;
    getFlagVariants(): Record<string, string | boolean>;
    getFlagPayloads(): Record<string, JsonType>;
    /**
     * Reloads feature flags asynchronously.
     *
     * Constraints:
     *
     * 1. Avoid parallel requests
     * 2. Delay a few milliseconds after each reloadFeatureFlags call to batch subsequent changes together
     */
    reloadFeatureFlags(): void;
    private _clearDebouncer;
    ensureFlagsLoaded(): void;
    setAnonymousDistinctId(anon_distinct_id: string): void;
    setReloadingPaused(isPaused: boolean): void;
    /**
     * NOTE: This is used both for flags and remote config. Once the RemoteConfig is fully released this will essentially only
     * be for flags and can eventually be replaced with the new flags endpoint
     */
    _callFlagsEndpoint(options?: {
        disableFlags?: boolean;
    }): void;
    getFeatureFlag(key: string, options?: {
        send_event?: boolean;
    }): boolean | string | undefined;
    getFeatureFlagDetails(key: string): FeatureFlagDetail | undefined;
    getFeatureFlagPayload(key: string): JsonType;
    getRemoteConfigPayload(key: string, callback: RemoteConfigFeatureFlagCallback): void;
    isFeatureEnabled(key: string, options?: {
        send_event?: boolean;
    }): boolean | undefined;
    addFeatureFlagsHandler(handler: FeatureFlagsCallback): void;
    removeFeatureFlagsHandler(handler: FeatureFlagsCallback): void;
    receivedFeatureFlags(response: Partial<FlagsResponse>, errorsLoading?: boolean): void;
    /**
     * @deprecated Use overrideFeatureFlags instead. This will be removed in a future version.
     */
    override(flags: boolean | string[] | Record<string, string | boolean>, suppressWarning?: boolean): void;
    /**
     * Override feature flags on the client-side. Useful for setting non-persistent feature flags,
     * or for testing/debugging feature flags in the PostHog app.
     *
     * ### Usage:
     *
     *     - posthog.featureFlags.overrideFeatureFlags(false) // clear all overrides
     *     - posthog.featureFlags.overrideFeatureFlags(['beta-feature']) // enable flags
     *     - posthog.featureFlags.overrideFeatureFlags({'beta-feature': 'variant'}) // set variants
     *     - posthog.featureFlags.overrideFeatureFlags({ // set both flags and payloads
     *         flags: {'beta-feature': 'variant'},
     *         payloads: { 'beta-feature': { someData: true } }
     *       })
     *     - posthog.featureFlags.overrideFeatureFlags({ // only override payloads
     *         payloads: { 'beta-feature': { someData: true } }
     *       })
     */
    overrideFeatureFlags(overrideOptions: OverrideFeatureFlagsOptions): void;
    onFeatureFlags(callback: FeatureFlagsCallback): () => void;
    updateEarlyAccessFeatureEnrollment(key: string, isEnrolled: boolean, stage?: string): void;
    getEarlyAccessFeatures(callback: EarlyAccessFeatureCallback, force_reload?: boolean, stages?: EarlyAccessFeatureStage[]): void;
    _prepareFeatureFlagsForCallbacks(): {
        flags: string[];
        flagVariants: Record<string, string | boolean>;
    };
    _fireFeatureFlagsCallbacks(errorsLoading?: boolean): void;
    /**
     * Set override person properties for feature flags.
     * This is used when dealing with new persons / where you don't want to wait for ingestion
     * to update user properties.
     */
    setPersonPropertiesForFlags(properties: Properties, reloadFeatureFlags?: boolean): void;
    resetPersonPropertiesForFlags(): void;
    /**
     * Set override group properties for feature flags.
     * This is used when dealing with new groups / where you don't want to wait for ingestion
     * to update properties.
     * Takes in an object, the key of which is the group type.
     * For example:
     *     setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } })
     */
    setGroupPropertiesForFlags(properties: {
        [type: string]: Properties;
    }, reloadFeatureFlags?: boolean): void;
    resetGroupPropertiesForFlags(group_type?: string): void;
    reset(): void;
}

declare class ActionMatcher {
    private readonly _actionRegistry?;
    private readonly _instance?;
    private readonly _actionEvents;
    private _debugEventEmitter;
    constructor(instance?: PostHog);
    init(): void;
    register(actions: SurveyActionType[]): void;
    on(eventName: string, eventPayload?: CaptureResult): void;
    _addActionHook(callback: (actionName: string, eventPayload?: any) => void): void;
    private _checkAction;
    onAction(event: 'actionCaptured', cb: (...args: any[]) => void): () => void;
    private _checkStep;
    private _checkStepEvent;
    private _checkStepUrl;
    private static _matchString;
    private static _escapeStringRegexp;
    private _checkStepElement;
    private _getElementsList;
}

declare class SurveyEventReceiver {
    private readonly _eventToSurveys;
    private readonly _actionToSurveys;
    private _actionMatcher?;
    private readonly _instance?;
    constructor(instance: PostHog);
    register(surveys: Survey[]): void;
    private _setupActionBasedSurveys;
    private _setupEventBasedSurveys;
    onEvent(event: string, eventPayload?: CaptureResult): void;
    onAction(actionName: string): void;
    private _updateActivatedSurveys;
    getSurveys(): string[];
    getEventToSurveys(): Map<string, string[]>;
    _getActionMatcher(): ActionMatcher | null | undefined;
}

declare class PostHogSurveys {
    private readonly _instance;
    private _isSurveysEnabled?;
    _surveyEventReceiver: SurveyEventReceiver | null;
    private _surveyManager;
    private _isFetchingSurveys;
    private _isInitializingSurveys;
    private _surveyCallbacks;
    constructor(_instance: PostHog);
    onRemoteConfig(response: RemoteConfig): void;
    reset(): void;
    loadIfEnabled(): void;
    /** Helper to finalize survey initialization */
    private _completeSurveyInitialization;
    /** Helper to handle errors during survey loading */
    private _handleSurveyLoadError;
    /**
     * Register a callback that runs when surveys are initialized.
     * ### Usage:
     *
     *     posthog.onSurveysLoaded((surveys) => {
     *         // You can work with all surveys
     *         console.log('All available surveys:', surveys)
     *
     *         // Or get active matching surveys
     *         posthog.getActiveMatchingSurveys((activeMatchingSurveys) => {
     *             if (activeMatchingSurveys.length > 0) {
     *                 posthog.renderSurvey(activeMatchingSurveys[0].id, '#survey-container')
     *             }
     *         })
     *     })
     *
     * @param {Function} callback The callback function will be called when surveys are loaded or updated.
     *                           It receives the array of all surveys and a context object with error status.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    onSurveysLoaded(callback: SurveyCallback): () => void;
    getSurveys(callback: SurveyCallback, forceReload?: boolean): void;
    /** Helper method to notify all registered callbacks */
    private _notifySurveyCallbacks;
    getActiveMatchingSurveys(callback: SurveyCallback, forceReload?: boolean): void;
    private _getSurveyById;
    private _checkSurveyEligibility;
    canRenderSurvey(surveyId: string): SurveyRenderReason;
    canRenderSurveyAsync(surveyId: string, forceReload: boolean): Promise<SurveyRenderReason>;
    renderSurvey(surveyId: string, selector: string): void;
}

declare class RateLimiter {
    instance: PostHog;
    serverLimits: Record<string, number>;
    captureEventsPerSecond: number;
    captureEventsBurstLimit: number;
    lastEventRateLimited: boolean;
    constructor(instance: PostHog);
    clientRateLimitContext(checkOnly?: boolean): {
        isRateLimited: boolean;
        remainingTokens: number;
    };
    isServerRateLimited(batchKey: string | undefined): boolean;
    checkForLimiting: (httpResponse: RequestResponse) => void;
}

declare class RequestQueue {
    private _isPaused;
    private _queue;
    private _flushTimeout?;
    private _flushTimeoutMs;
    private _sendRequest;
    constructor(sendRequest: (req: QueuedRequestWithOptions) => void, config?: RequestQueueConfig);
    enqueue(req: QueuedRequestWithOptions): void;
    unload(): void;
    enable(): void;
    private _setFlushTimeout;
    private _clearFlushTimeout;
    private _formatQueue;
}

declare class RetryQueue {
    private _instance;
    private _isPolling;
    private _poller;
    private _pollIntervalMs;
    private _queue;
    private _areWeOnline;
    constructor(_instance: PostHog);
    get length(): number;
    retriableRequest({ retriesPerformedSoFar, ...options }: RetriableRequestWithOptions): void;
    private _enqueue;
    private _poll;
    private _flush;
    unload(): void;
}

interface ScrollContext {
    maxScrollHeight?: number;
    maxScrollY?: number;
    lastScrollY?: number;
    maxContentHeight?: number;
    maxContentY?: number;
    lastContentY?: number;
}
declare class ScrollManager {
    private _instance;
    private _context;
    constructor(_instance: PostHog);
    getContext(): ScrollContext | undefined;
    resetContext(): ScrollContext | undefined;
    private _updateScrollData;
    startMeasuringScrollPosition(): void;
    scrollElement(): Element | undefined;
    scrollY(): number;
    scrollX(): number;
}

interface LegacySessionSourceProps {
    initialPathName: string;
    referringDomain: string;
    utm_medium?: string;
    utm_source?: string;
    utm_campaign?: string;
    utm_content?: string;
    utm_term?: string;
}
interface CurrentSessionSourceProps {
    r: string;
    u: string | undefined;
}
interface StoredSessionSourceProps {
    sessionId: string;
    props: LegacySessionSourceProps | CurrentSessionSourceProps;
}
declare class SessionPropsManager {
    private readonly _instance;
    private readonly _sessionIdManager;
    private readonly _persistence;
    private readonly _sessionSourceParamGenerator;
    constructor(instance: PostHog, sessionIdManager: SessionIdManager, persistence: PostHogPersistence, sessionSourceParamGenerator?: (instance?: PostHog) => LegacySessionSourceProps | CurrentSessionSourceProps);
    _getStored(): StoredSessionSourceProps | undefined;
    _onSessionIdCallback: (sessionId: string) => void;
    getSetOnceProps(): Record<string, any>;
    getSessionProps(): Record<string, any>;
}

declare class SiteApps {
    private _instance;
    apps: Record<string, SiteApp>;
    private _stopBuffering?;
    private _bufferedInvocations;
    constructor(_instance: PostHog);
    get isEnabled(): boolean;
    private _eventCollector;
    get siteAppLoaders(): SiteAppLoader[] | undefined;
    init(): void;
    globalsForEvent(event: CaptureResult): SiteAppGlobals;
    setupSiteApp(loader: SiteAppLoader): void;
    private _setupSiteApps;
    private _onCapturedEvent;
    onRemoteConfig(response: RemoteConfig): void;
}

/**
 * The request router helps simplify the logic to determine which endpoints should be called for which things
 * The basic idea is that for a given region (US or EU), we have a set of endpoints that we should call depending
 * on the type of request (events, replays, flags, etc.) and handle overrides that may come from configs or the flags endpoint
 */
declare enum RequestRouterRegion {
    US = "us",
    EU = "eu",
    CUSTOM = "custom"
}
type RequestRouterTarget = 'api' | 'ui' | 'assets';
declare class RequestRouter {
    instance: PostHog;
    private _regionCache;
    constructor(instance: PostHog);
    get apiHost(): string;
    get uiHost(): string | undefined;
    get region(): RequestRouterRegion;
    endpointFor(target: RequestRouterTarget, path?: string): string;
}

interface WebExperimentTransform {
    attributes?: {
        name: string;
        value: string;
    }[];
    selector?: string;
    text?: string;
    html?: string;
    imgUrl?: string;
    css?: string;
}
type WebExperimentUrlMatchType = 'regex' | 'not_regex' | 'exact' | 'is_not' | 'icontains' | 'not_icontains';
interface WebExperimentVariant {
    conditions?: {
        url?: string;
        urlMatchType?: WebExperimentUrlMatchType;
        utm?: {
            utm_source?: string;
            utm_medium?: string;
            utm_campaign?: string;
            utm_term?: string;
        };
    };
    variant_name: string;
    transforms: WebExperimentTransform[];
}
interface WebExperiment {
    id: number;
    name: string;
    feature_flag_key?: string;
    variants: Record<string, WebExperimentVariant>;
}
type WebExperimentsCallback = (webExperiments: WebExperiment[]) => void;

declare class WebExperiments {
    private _instance;
    private _flagToExperiments?;
    constructor(_instance: PostHog);
    onFeatureFlags(flags: string[]): void;
    previewWebExperiment(): void;
    loadIfEnabled(): void;
    getWebExperimentsAndEvaluateDisplayLogic: (forceReload?: boolean) => void;
    getWebExperiments(callback: WebExperimentsCallback, forceReload: boolean, previewing?: boolean): void;
    private _showPreviewWebExperiment;
    private static _matchesTestVariant;
    private static _matchUrlConditions;
    static getWindowLocation(): Location | undefined;
    private static _matchUTMConditions;
    private static _logInfo;
    private _applyTransforms;
    _is_bot(): boolean | undefined;
}

declare class ExternalIntegrations {
    private readonly _instance;
    constructor(_instance: PostHog);
    private _loadScript;
    startIfEnabledOrStop(): void;
}

type OnlyValidKeys<T, Shape> = T extends Shape ? (Exclude<keyof T, keyof Shape> extends never ? T : never) : never;
declare class DeprecatedWebPerformanceObserver {
    get _forceAllowLocalhost(): boolean;
    set _forceAllowLocalhost(value: boolean);
    private __forceAllowLocalhost;
}
/**
 *
 * This is the SDK reference for the PostHog JavaScript Web SDK.
 * You can learn more about example usage in the
 * [JavaScript Web SDK documentation](/docs/libraries/js).
 * You can also follow [framework specific guides](/docs/frameworks)
 * to integrate PostHog into your project.
 *
 * This SDK is designed for browser environments.
 * Use the PostHog [Node.js SDK](/docs/libraries/node) for server-side usage.
 *
 * @constructor
 */
declare class PostHog {
    __loaded: boolean;
    config: PostHogConfig;
    _originalUserConfig?: Partial<PostHogConfig>;
    rateLimiter: RateLimiter;
    scrollManager: ScrollManager;
    pageViewManager: PageViewManager;
    featureFlags: PostHogFeatureFlags;
    surveys: PostHogSurveys;
    experiments: WebExperiments;
    toolbar: Toolbar;
    exceptions: PostHogExceptions;
    consent: ConsentManager;
    persistence?: PostHogPersistence;
    sessionPersistence?: PostHogPersistence;
    sessionManager?: SessionIdManager;
    sessionPropsManager?: SessionPropsManager;
    requestRouter: RequestRouter;
    siteApps?: SiteApps;
    autocapture?: Autocapture;
    heatmaps?: Heatmaps;
    webVitalsAutocapture?: WebVitalsAutocapture;
    exceptionObserver?: ExceptionObserver;
    deadClicksAutocapture?: DeadClicksAutocapture;
    historyAutocapture?: HistoryAutocapture;
    _requestQueue?: RequestQueue;
    _retryQueue?: RetryQueue;
    sessionRecording?: SessionRecording;
    externalIntegrations?: ExternalIntegrations;
    webPerformance: DeprecatedWebPerformanceObserver;
    _initialPageviewCaptured: boolean;
    _visibilityStateListener: (() => void) | null;
    _personProcessingSetOncePropertiesSent: boolean;
    _triggered_notifs: any;
    compression?: Compression;
    __request_queue: QueuedRequestWithOptions[];
    analyticsDefaultEndpoint: string;
    version: string;
    _initialPersonProfilesConfig: 'always' | 'never' | 'identified_only' | null;
    _cachedPersonProperties: string | null;
    SentryIntegration: typeof SentryIntegration;
    sentryIntegration: (options?: SentryIntegrationOptions) => ReturnType<typeof sentryIntegration>;
    private _internalEventEmitter;
    /** @deprecated Use `flagsEndpointWasHit` instead.  We migrated to using a new feature flag endpoint and the new method is more semantically accurate */
    get decideEndpointWasHit(): boolean;
    get flagsEndpointWasHit(): boolean;
    /** DEPRECATED: We keep this to support existing usage but now one should just call .setPersonProperties */
    people: {
        set: (prop: string | Properties, to?: string, callback?: RequestCallback) => void;
        set_once: (prop: string | Properties, to?: string, callback?: RequestCallback) => void;
    };
    constructor();
    /**
     * Initializes a new instance of the PostHog capturing object.
     *
     * @remarks
     * All new instances are added to the main posthog object as sub properties (such as
     * `posthog.library_name`) and also returned by this function. [Learn more about configuration options](https://github.com/posthog/posthog-js/blob/6e0e873/src/posthog-core.js#L57-L91)
     *
     * @example
     * ```js
     * // basic initialization
     * posthog.init('<ph_project_api_key>', {
     *     api_host: '<ph_client_api_host>'
     * })
     * ```
     *
     * @example
     * ```js
     * // multiple instances
     * posthog.init('<ph_project_api_key>', {}, 'project1')
     * posthog.init('<ph_project_api_key>', {}, 'project2')
     * ```
     *
     * @public
     *
     * @param token - Your PostHog API token
     * @param config - A dictionary of config options to override
     * @param name - The name for the new posthog instance that you want created
     *
     * {@label Initialization}
     *
     * @returns The newly initialized PostHog instance
     */
    init(token: string, config?: OnlyValidKeys<Partial<PostHogConfig>, Partial<PostHogConfig>>, name?: string): PostHog;
    _init(token: string, config?: Partial<PostHogConfig>, name?: string): PostHog;
    _onRemoteConfig(config: RemoteConfig): void;
    _loaded(): void;
    _start_queue_if_opted_in(): void;
    _dom_loaded(): void;
    _handle_unload(): void;
    _send_request(options: QueuedRequestWithOptions): void;
    _send_retriable_request(options: QueuedRequestWithOptions): void;
    /**
     * _execute_array() deals with processing any posthog function
     * calls that were called before the PostHog library were loaded
     * (and are thus stored in an array so they can be called later)
     *
     * Note: we fire off all the posthog function calls && user defined
     * functions BEFORE we fire off posthog capturing calls. This is so
     * identify/register/set_config calls can properly modify early
     * capturing calls.
     *
     * @param {Array} array
     */
    _execute_array(array: SnippetArrayItem[]): void;
    _hasBootstrappedFeatureFlags(): boolean;
    /**
     * push() keeps the standard async-array-push
     * behavior around after the lib is loaded.
     * This is only useful for external integrations that
     * do not wish to rely on our convenience methods
     * (created in the snippet).
     *
     * @example
     * ```js
     * posthog.push(['register', { a: 'b' }]);
     * ```
     *
     * @param {Array} item A [function_name, args...] array to be executed
     */
    push(item: SnippetArrayItem): void;
    /**
     * Captures an event with optional properties and configuration.
     *
     * @remarks
     * You can capture arbitrary object-like values as events. [Learn about capture best practices](/docs/product-analytics/capture-events)
     *
     * @example
     * ```js
     * // basic event capture
     * posthog.capture('cta-button-clicked', {
     *     button_name: 'Get Started',
     *     page: 'homepage'
     * })
     * ```
     *
     * {@label Capture}
     *
     * @public
     *
     * @param event_name - The name of the event (e.g., 'Sign Up', 'Button Click', 'Purchase')
     * @param properties - Properties to include with the event describing the user or event details
     * @param options - Optional configuration for the capture request
     *
     * @returns The capture result containing event data, or undefined if capture failed
     */
    capture(event_name: EventName, properties?: Properties | null, options?: CaptureOptions): CaptureResult | undefined;
    _addCaptureHook(callback: (eventName: string, eventPayload?: CaptureResult) => void): () => void;
    /**
     * This method is used internally to calculate the event properties before sending it to PostHog. It can also be
     * used by integrations (e.g. Segment) to enrich events with PostHog properties before sending them to Segment,
     * which is required for some PostHog products to work correctly. (e.g. to have a correct $session_id property).
     *
     * @param {String} eventName The name of the event. This can be anything the user does - 'Button Click', 'Sign Up', '$pageview', etc.
     * @param {Object} eventProperties The properties to include with the event.
     * @param {Date} [timestamp] The timestamp of the event, e.g. for calculating time on page. If not set, it'll automatically be set to the current time.
     * @param {String} [uuid] The uuid of the event, e.g. for storing the $pageview ID.
     * @param {Boolean} [readOnly] Set this if you do not intend to actually send the event, and therefore do not want to update internal state e.g. session timeout
     *
     * @internal
     */
    calculateEventProperties(eventName: string, eventProperties: Properties, timestamp?: Date, uuid?: string, readOnly?: boolean): Properties;
    /** @deprecated - deprecated in 1.241.0, use `calculateEventProperties` instead  */
    _calculate_event_properties: (eventName: string, eventProperties: Properties, timestamp?: Date, uuid?: string, readOnly?: boolean) => Properties;
    /**
     * Add additional set_once properties to the event when creating a person profile. This allows us to create the
     * profile with mostly-accurate properties, despite earlier events not setting them. We do this by storing them in
     * persistence.
     * @param dataSetOnce
     */
    _calculate_set_once_properties(dataSetOnce?: Properties): Properties | undefined;
    /**
     * Registers super properties that are included with all events.
     *
     * @remarks
     * Super properties are stored in persistence and automatically added to every event you capture.
     * These values will overwrite any existing super properties with the same keys.
     *
     * @example
     * ```js
     * // register a single property
     * posthog.register({ plan: 'premium' })
     * ```
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // register multiple properties
     * posthog.register({
     *     email: 'user@example.com',
     *     account_type: 'business',
     *     signup_date: '2023-01-15'
     * })
     * ```
     *
     * @example
     * ```js
     * // register with custom expiration
     * posthog.register({ campaign: 'summer_sale' }, 7) // expires in 7 days
     * ```
     *
     * @public
     *
     * @param {Object} properties properties to store about the user
     * @param {Number} [days] How many days since the user's last visit to store the super properties
     */
    register(properties: Properties, days?: number): void;
    /**
     * Registers super properties only if they haven't been set before.
     *
     * @remarks
     * Unlike `register()`, this method will not overwrite existing super properties.
     * Use this for properties that should only be set once, like signup date or initial referrer.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // register once-only properties
     * posthog.register_once({
     *     first_login_date: new Date().toISOString(),
     *     initial_referrer: document.referrer
     * })
     * ```
     *
     * @example
     * ```js
     * // override existing value if it matches default
     * posthog.register_once(
     *     { user_type: 'premium' },
     *     'unknown'  // overwrite if current value is 'unknown'
     * )
     * ```
     *
     * @public
     *
     * @param {Object} properties An associative array of properties to store about the user
     * @param {*} [default_value] Value to override if already set in super properties (ex: 'False') Default: 'None'
     * @param {Number} [days] How many days since the users last visit to store the super properties
     */
    register_once(properties: Properties, default_value?: Property, days?: number): void;
    /**
     * Registers super properties for the current session only.
     *
     * @remarks
     * Session super properties are automatically added to all events during the current browser session.
     * Unlike regular super properties, these are cleared when the session ends and are stored in sessionStorage.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // register session-specific properties
     * posthog.register_for_session({
     *     current_page_type: 'checkout',
     *     ab_test_variant: 'control'
     * })
     * ```
     *
     * @example
     * ```js
     * // register properties for user flow tracking
     * posthog.register_for_session({
     *     selected_plan: 'pro',
     *     completed_steps: 3,
     *     flow_id: 'signup_flow_v2'
     * })
     * ```
     *
     * @public
     *
     * @param {Object} properties An associative array of properties to store about the user
     */
    register_for_session(properties: Properties): void;
    /**
     * Removes a super property from persistent storage.
     *
     * @remarks
     * This will stop the property from being automatically included in future events.
     * The property will be permanently removed from the user's profile.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // remove a super property
     * posthog.unregister('plan_type')
     * ```
     *
     * @public
     *
     * @param {String} property The name of the super property to remove
     */
    unregister(property: string): void;
    /**
     * Removes a session super property from the current session.
     *
     * @remarks
     * This will stop the property from being automatically included in future events for this session.
     * The property is removed from sessionStorage.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // remove a session property
     * posthog.unregister_for_session('current_flow')
     * ```
     *
     * @public
     *
     * @param {String} property The name of the session super property to remove
     */
    unregister_for_session(property: string): void;
    _register_single(prop: string, value: Property): void;
    /**
     * Gets the value of a feature flag for the current user.
     *
     * @remarks
     * Returns the feature flag value which can be a boolean, string, or undefined.
     * Supports multivariate flags that can return custom string values.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * // check boolean flag
     * if (posthog.getFeatureFlag('new-feature')) {
     *     // show new feature
     * }
     * ```
     *
     * @example
     * ```js
     * // check multivariate flag
     * const variant = posthog.getFeatureFlag('button-color')
     * if (variant === 'red') {
     *     // show red button
     * }
     * ```
     *
     * @public
     *
     * @param {Object|String} prop Key of the feature flag.
     * @param {Object|String} options (optional) If {send_event: false}, we won't send an $feature_flag_call event to PostHog.
     */
    getFeatureFlag(key: string, options?: {
        send_event?: boolean;
    }): boolean | string | undefined;
    /**
     * Get feature flag payload value matching key for user (supports multivariate flags).
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * if(posthog.getFeatureFlag('beta-feature') === 'some-value') {
     *      const someValue = posthog.getFeatureFlagPayload('beta-feature')
     *      // do something
     * }
     * ```
     *
     * @public
     *
     * @param {Object|String} prop Key of the feature flag.
     */
    getFeatureFlagPayload(key: string): JsonType;
    /**
     * Checks if a feature flag is enabled for the current user.
     *
     * @remarks
     * Returns true if the flag is enabled, false if disabled, or undefined if not found.
     * This is a convenience method that treats any truthy value as enabled.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * // simple feature flag check
     * if (posthog.isFeatureEnabled('new-checkout')) {
     *     showNewCheckout()
     * }
     * ```
     *
     * @example
     * ```js
     * // disable event tracking
     * if (posthog.isFeatureEnabled('feature', { send_event: false })) {
     *     // flag checked without sending $feature_flag_call event
     * }
     * ```
     *
     * @public
     *
     * @param {Object|String} prop Key of the feature flag.
     * @param {Object|String} options (optional) If {send_event: false}, we won't send an $feature_flag_call event to PostHog.
     */
    isFeatureEnabled(key: string, options?: {
        send_event: boolean;
    }): boolean | undefined;
    /**
     * Feature flag values are cached. If something has changed with your user and you'd like to refetch their flag values, call this method.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * posthog.reloadFeatureFlags()
     * ```
     *
     * @public
     */
    reloadFeatureFlags(): void;
    /**
     * Opt the user in or out of an early access feature. [Learn more in the docs](/docs/feature-flags/early-access-feature-management#option-2-custom-implementation)
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * const toggleBeta = (betaKey) => {
     *   if (activeBetas.some(
     *     beta => beta.flagKey === betaKey
     *   )) {
     *     posthog.updateEarlyAccessFeatureEnrollment(
     *       betaKey,
     *       false
     *     )
     *     setActiveBetas(
     *       prevActiveBetas => prevActiveBetas.filter(
     *         item => item.flagKey !== betaKey
     *       )
     *     );
     *     return
     *   }
     *
     *   posthog.updateEarlyAccessFeatureEnrollment(
     *     betaKey,
     *     true
     *   )
     *   setInactiveBetas(
     *     prevInactiveBetas => prevInactiveBetas.filter(
     *       item => item.flagKey !== betaKey
     *     )
     *   );
     * }
     *
     * const registerInterest = (featureKey) => {
     *   posthog.updateEarlyAccessFeatureEnrollment(
     *     featureKey,
     *     true
     *   )
     *   // Update UI to show user has registered
     * }
     * ```
     *
     * @public
     *
     * @param {String} key The key of the feature flag to update.
     * @param {Boolean} isEnrolled Whether the user is enrolled in the feature.
     * @param {String} [stage] The stage of the feature flag to update.
     */
    updateEarlyAccessFeatureEnrollment(key: string, isEnrolled: boolean, stage?: string): void;
    /**
     * Get the list of early access features. To check enrollment status, use `isFeatureEnabled`. [Learn more in the docs](/docs/feature-flags/early-access-feature-management#option-2-custom-implementation)
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * const posthog = usePostHog()
     * const activeFlags = useActiveFeatureFlags()
     *
     * const [activeBetas, setActiveBetas] = useState([])
     * const [inactiveBetas, setInactiveBetas] = useState([])
     * const [comingSoonFeatures, setComingSoonFeatures] = useState([])
     *
     * useEffect(() => {
     *   posthog.getEarlyAccessFeatures((features) => {
     *     // Filter features by stage
     *     const betaFeatures = features.filter(feature => feature.stage === 'beta')
     *     const conceptFeatures = features.filter(feature => feature.stage === 'concept')
     *
     *     setComingSoonFeatures(conceptFeatures)
     *
     *     if (!activeFlags || activeFlags.length === 0) {
     *       setInactiveBetas(betaFeatures)
     *       return
     *     }
     *
     *     const activeBetas = betaFeatures.filter(
     *             beta => activeFlags.includes(beta.flagKey)
     *         );
     *     const inactiveBetas = betaFeatures.filter(
     *             beta => !activeFlags.includes(beta.flagKey)
     *         );
     *     setActiveBetas(activeBetas)
     *     setInactiveBetas(inactiveBetas)
     *   }, true, ['concept', 'beta'])
     * }, [activeFlags])
     * ```
     *
     * @public
     *
     * @param {Function} callback The callback function will be called when the early access features are loaded.
     * @param {Boolean} [force_reload] Whether to force a reload of the early access features.
     * @param {String[]} [stages] The stages of the early access features to load.
     */
    getEarlyAccessFeatures(callback: EarlyAccessFeatureCallback, force_reload?: boolean, stages?: EarlyAccessFeatureStage[]): void;
    /**
     * Exposes a set of events that PostHog will emit.
     * e.g. `eventCaptured` is emitted immediately before trying to send an event
     *
     * Unlike  `onFeatureFlags` and `onSessionId` these are not called when the
     * listener is registered, the first callback will be the next event
     * _after_ registering a listener
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * posthog.on('eventCaptured', (event) => {
     *   console.log(event)
     * })
     * ```
     *
     * @public
     *
     * @param {String} event The event to listen for.
     * @param {Function} cb The callback function to call when the event is emitted.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    on(event: 'eventCaptured', cb: (...args: any[]) => void): () => void;
    /**
     * Register an event listener that runs when feature flags become available or when they change.
     * If there are flags, the listener is called immediately in addition to being called on future changes.
     * Note that this is not called only when we fetch feature flags from the server, but also when they change in the browser.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * posthog.onFeatureFlags(function(featureFlags, featureFlagsVariants, { errorsLoading }) {
     *     // do something
     * })
     * ```
     *
     * @param callback - The callback function will be called once the feature flags are ready or when they are updated.
     *                   It'll return a list of feature flags enabled for the user, the variants,
     *                   and also a context object indicating whether we succeeded to fetch the flags or not.
     * @returns A function that can be called to unsubscribe the listener. Used by `useEffect` when the component unmounts.
     */
    onFeatureFlags(callback: FeatureFlagsCallback): () => void;
    /**
     * Register an event listener that runs when surveys are loaded.
     *
     * Callback parameters:
     * - surveys: Survey[]: An array containing all survey objects fetched from PostHog using the getSurveys method
     * - context: { isLoaded: boolean, error?: string }: An object indicating if the surveys were loaded successfully
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.onSurveysLoaded((surveys, context) => { // do something })
     * ```
     *
     *
     * @param {Function} callback The callback function will be called when surveys are loaded or updated.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    onSurveysLoaded(callback: SurveyCallback): () => void;
    /**
     * Register an event listener that runs whenever the session id or window id change.
     * If there is already a session id, the listener is called immediately in addition to being called on future changes.
     *
     * Can be used, for example, to sync the PostHog session id with a backend session.
     *
     * {@label Identification}
     *
     * @example
     * ```js
     * posthog.onSessionId(function(sessionId, windowId) { // do something })
     * ```
     *
     * @param {Function} [callback] The callback function will be called once a session id is present or when it or the window id are updated.
     * @returns {Function} A function that can be called to unsubscribe the listener. E.g. Used by `useEffect` when the component unmounts.
     */
    onSessionId(callback: SessionIdChangedCallback): () => void;
    /**
     * Get list of all surveys.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * function callback(surveys, context) {
     *   // do something
     * }
     *
     * posthog.getSurveys(callback, false)
     * ```
     *
     * @public
     *
     * @param {Function} [callback] Function that receives the array of surveys
     * @param {Boolean} [forceReload] Optional boolean to force an API call for updated surveys
     */
    getSurveys(callback: SurveyCallback, forceReload?: boolean): void;
    /**
     * Get surveys that should be enabled for the current user. See [fetching surveys documentation](/docs/surveys/implementing-custom-surveys#fetching-surveys-manually) for more details.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.getActiveMatchingSurveys((surveys) => {
     *      // do something
     * })
     * ```
     *
     * @public
     *
     * @param {Function} [callback] The callback function will be called when the surveys are loaded or updated.
     * @param {Boolean} [forceReload] Whether to force a reload of the surveys.
     */
    getActiveMatchingSurveys(callback: SurveyCallback, forceReload?: boolean): void;
    /**
     * Although we recommend using popover surveys and display conditions,
     * if you want to show surveys programmatically without setting up all
     * the extra logic needed for API surveys, you can render surveys
     * programmatically with the renderSurvey method.
     *
     * This takes a survey ID and an HTML selector to render an unstyled survey.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.renderSurvey(coolSurveyID, '#survey-container')
     * ```
     *
     * @public
     *
     * @param {String} surveyId The ID of the survey to render.
     * @param {String} selector The selector of the HTML element to render the survey on.
     */
    renderSurvey(surveyId: string, selector: string): void;
    /**
     * Checks the feature flags associated with this Survey to see if the survey can be rendered.
     * This method is deprecated because it's synchronous and won't return the correct result if surveys are not loaded.
     * Use `canRenderSurveyAsync` instead.
     *
     * {@label Surveys}
     *
     *
     * @deprecated
     *
     * @param surveyId The ID of the survey to check.
     * @returns A SurveyRenderReason object indicating if the survey can be rendered.
     */
    canRenderSurvey(surveyId: string): SurveyRenderReason | null;
    /**
     * Checks the feature flags associated with this Survey to see if the survey can be rendered.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.canRenderSurveyAsync(surveyId).then((result) => {
     *     if (result.visible) {
     *         // Survey can be rendered
     *         console.log('Survey can be rendered')
     *     } else {
     *         // Survey cannot be rendered
     *         console.log('Survey cannot be rendered:', result.disabledReason)
     *     }
     * })
     * ```
     *
     * @public
     *
     * @param surveyId The ID of the survey to check.
     * @param forceReload If true, the survey will be reloaded from the server, Default: false
     * @returns A SurveyRenderReason object indicating if the survey can be rendered.
     */
    canRenderSurveyAsync(surveyId: string, forceReload?: boolean): Promise<SurveyRenderReason>;
    /**
     * Associates a user with a unique identifier instead of an auto-generated ID.
     * Learn more about [identifying users](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @remarks
     * By default, PostHog assigns each user a randomly generated `distinct_id`. Use this method to
     * replace that ID with your own unique identifier (like a user ID from your database).
     *
     * @example
     * ```js
     * // basic identification
     * posthog.identify('user_12345')
     * ```
     *
     * @example
     * ```js
     * // identify with user properties
     * posthog.identify('user_12345', {
     *     email: 'user@example.com',
     *     plan: 'premium'
     * })
     * ```
     *
     * @example
     * ```js
     * // identify with set and set_once properties
     * posthog.identify('user_12345',
     *     { last_login: new Date() },  // updates every time
     *     { signup_date: new Date() }  // sets only once
     * )
     * ```
     *
     * @public
     *
     * @param {String} [new_distinct_id] A string that uniquely identifies a user. If not provided, the distinct_id currently in the persistent store (cookie or localStorage) will be used.
     * @param {Object} [userPropertiesToSet] Optional: An associative array of properties to store about the user. Note: For feature flag evaluations, if the same key is present in the userPropertiesToSetOnce,
     *  it will be overwritten by the value in userPropertiesToSet.
     * @param {Object} [userPropertiesToSetOnce] Optional: An associative array of properties to store about the user. If property is previously set, this does not override that value.
     */
    identify(new_distinct_id?: string, userPropertiesToSet?: Properties, userPropertiesToSetOnce?: Properties): void;
    /**
     * Sets properties on the person profile associated with the current `distinct_id`.
     * Learn more about [identifying users](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @remarks
     * Updates user properties that are stored with the person profile in PostHog.
     * If `person_profiles` is set to `identified_only` and no profile exists, this will create one.
     *
     * @example
     * ```js
     * // set user properties
     * posthog.setPersonProperties({
     *     email: 'user@example.com',
     *     plan: 'premium'
     * })
     * ```
     *
     * @example
     * ```js
     * // set properties
     * posthog.setPersonProperties(
     *     { name: 'Max Hedgehog' },  // $set properties
     *     { initial_url: '/blog' }   // $set_once properties
     * )
     * ```
     *
     * @public
     *
     * @param {Object} [userPropertiesToSet] Optional: An associative array of properties to store about the user. Note: For feature flag evaluations, if the same key is present in the userPropertiesToSetOnce,
     *  it will be overwritten by the value in userPropertiesToSet.
     * @param {Object} [userPropertiesToSetOnce] Optional: An associative array of properties to store about the user. If property is previously set, this does not override that value.
     */
    setPersonProperties(userPropertiesToSet?: Properties, userPropertiesToSetOnce?: Properties): void;
    /**
     * Associates the user with a group for group-based analytics.
     * Learn more about [groups](/docs/product-analytics/group-analytics)
     *
     * {@label Identification}
     *
     * @remarks
     * Groups allow you to analyze users collectively (e.g., by organization, team, or account).
     * This sets the group association for all subsequent events and reloads feature flags.
     *
     * @example
     * ```js
     * // associate user with an organization
     * posthog.group('organization', 'org_12345', {
     *     name: 'Acme Corp',
     *     plan: 'enterprise'
     * })
     * ```
     *
     * @example
     * ```js
     * // associate with multiple group types
     * posthog.group('organization', 'org_12345')
     * posthog.group('team', 'team_67890')
     * ```
     *
     * @public
     *
     * @param {String} groupType Group type (example: 'organization')
     * @param {String} groupKey Group key (example: 'org::5')
     * @param {Object} groupPropertiesToSet Optional properties to set for group
     */
    group(groupType: string, groupKey: string, groupPropertiesToSet?: Properties): void;
    /**
     * Resets only the group properties of the user currently logged in.
     * Learn more about [groups](/docs/product-analytics/group-analytics)
     *
     * {@label Identification}
     *
     * @example
     * ```js
     * posthog.resetGroups()
     * ```
     *
     * @public
     */
    resetGroups(): void;
    /**
     * Sometimes, you might want to evaluate feature flags using properties that haven't been ingested yet,
     * or were set incorrectly earlier. You can do so by setting properties the flag depends on with these calls:
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * // Set properties
     * posthog.setPersonPropertiesForFlags({'property1': 'value', property2: 'value2'})
     * ```
     *
     * @example
     * ```js
     * // Set properties without reloading
     * posthog.setPersonPropertiesForFlags({'property1': 'value', property2: 'value2'}, false)
     * ```
     *
     * @public
     *
     * @param {Object} properties The properties to override.
     * @param {Boolean} [reloadFeatureFlags] Whether to reload feature flags.
     */
    setPersonPropertiesForFlags(properties: Properties, reloadFeatureFlags?: boolean): void;
    /**
     * Resets the person properties for feature flags.
     *
     * {@label Feature flags}
     *
     * @public
     *
     * @example
     * ```js
     * posthog.resetPersonPropertiesForFlags()
     * ```
     */
    resetPersonPropertiesForFlags(): void;
    /**
     * Set override group properties for feature flags.
     * This is used when dealing with new groups / where you don't want to wait for ingestion
     * to update properties.
     * Takes in an object, the key of which is the group type.
     *
     * {@label Feature flags}
     *
     * @public
     *
     * @example
     * ```js
     * // Set properties with reload
     * posthog.setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } })
     * ```
     *
     * @example
     * ```js
     * // Set properties without reload
     * posthog.setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } }, false)
     * ```
     *
     * @param {Object} properties The properties to override, the key of which is the group type.
     * @param {Boolean} [reloadFeatureFlags] Whether to reload feature flags.
     */
    setGroupPropertiesForFlags(properties: {
        [type: string]: Properties;
    }, reloadFeatureFlags?: boolean): void;
    /**
     * Resets the group properties for feature flags.
     *
     * {@label Feature flags}
     *
     * @public
     *
     * @example
     * ```js
     * posthog.resetGroupPropertiesForFlags()
     * ```
     */
    resetGroupPropertiesForFlags(group_type?: string): void;
    /**
     * Resets all user data and starts a fresh session.
     *
     * ⚠️ **Warning**: Only call this when a user logs out. Calling at the wrong time can cause split sessions.
     *
     * This clears:
     * - Session ID and super properties
     * - User identification (sets new random distinct_id)
     * - Cached data and consent settings
     *
     * {@label Identification}
     * @example
     * ```js
     * // reset on user logout
     * function logout() {
     *     posthog.reset()
     *     // redirect to login page
     * }
     * ```
     *
     * @example
     * ```js
     * // reset and generate new device ID
     * posthog.reset(true)  // also resets device_id
     * ```
     *
     * @public
     */
    reset(reset_device_id?: boolean): void;
    /**
     * Returns the current distinct ID for the user.
     *
     * @remarks
     * This is either the auto-generated ID or the ID set via `identify()`.
     * The distinct ID is used to associate events with users in PostHog.
     *
     * {@label Identification}
     *
     * @example
     * ```js
     * // get the current user ID
     * const userId = posthog.get_distinct_id()
     * console.log('Current user:', userId)
     * ```
     *
     * @example
     * ```js
     * // use in loaded callback
     * posthog.init('token', {
     *     loaded: (posthog) => {
     *         const id = posthog.get_distinct_id()
     *         // use the ID
     *     }
     * })
     * ```
     *
     * @public
     *
     * @returns The current distinct ID
     */
    get_distinct_id(): string;
    /**
     * Returns the current groups.
     *
     * {@label Identification}
     *
     * @public
     *
     * @returns The current groups
     */
    getGroups(): Record<string, any>;
    /**
     * Returns the current session_id.
     *
     * @remarks
     * This should only be used for informative purposes.
     * Any actual internal use case for the session_id should be handled by the sessionManager.
     *
     * {@label Session replay}
     *
     * @public
     *
     * @returns The current session_id
     */
    get_session_id(): string;
    /**
     * Returns the Replay url for the current session.
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // basic usage
     * posthog.get_session_replay_url()
     *
     * @example
     * ```js
     * // timestamp
     * posthog.get_session_replay_url({ withTimestamp: true })
     * ```
     *
     * @example
     * ```js
     * // timestamp and lookback
     * posthog.get_session_replay_url({
     *   withTimestamp: true,
     *   timestampLookBack: 30 // look back 30 seconds
     * })
     * ```
     *
     * @param options Options for the url
     * @param options.withTimestamp Whether to include the timestamp in the url (defaults to false)
     * @param options.timestampLookBack How many seconds to look back for the timestamp (defaults to 10)
     */
    get_session_replay_url(options?: {
        withTimestamp?: boolean;
        timestampLookBack?: number;
    }): string;
    /**
     * Creates an alias linking two distinct user identifiers. Learn more about [identifying users](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @remarks
     * PostHog will use this to link two distinct_ids going forward (not retroactively).
     * Call this when a user signs up to connect their anonymous session with their account.
     *
     *
     * @example
     * ```js
     * // link anonymous user to account on signup
     * posthog.alias('user_12345')
     * ```
     *
     * @example
     * ```js
     * // explicit alias with original ID
     * posthog.alias('user_12345', 'anonymous_abc123')
     * ```
     *
     * @public
     *
     * @param {String} alias A unique identifier that you want to use for this user in the future.
     * @param {String} [original] The current identifier being used for this user.
     */
    alias(alias: string, original?: string): CaptureResult | void | number;
    /**
     * Updates the configuration of the PostHog instance.
     *
     * {@label Initialization}
     *
     * @public
     *
     * @param {Partial<PostHogConfig>} config A dictionary of new configuration values to update
     */
    set_config(config: Partial<PostHogConfig>): void;
    /**
     * turns session recording on, and updates the config option `disable_session_recording` to false
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // Start and ignore controls
     * posthog.startSessionRecording(true)
     * ```
     *
     * @example
     * ```js
     * // Start and override controls
     * posthog.startSessionRecording({
     *   // you don't have to send all of these
     *   sampling: true || false,
     *   linked_flag: true || false,
     *   url_trigger: true || false,
     *   event_trigger: true || false
     * })
     * ```
     *
     * @param override.sampling - optional boolean to override the default sampling behavior - ensures the next session recording to start will not be skipped by sampling config.
     * @param override.linked_flag - optional boolean to override the default linked_flag behavior - ensures the next session recording to start will not be skipped by linked_flag config.
     * @param override.url_trigger - optional boolean to override the default url_trigger behavior - ensures the next session recording to start will not be skipped by url_trigger config.
     * @param override.event_trigger - optional boolean to override the default event_trigger behavior - ensures the next session recording to start will not be skipped by event_trigger config.
     * @param override - optional boolean to override the default sampling behavior - ensures the next session recording to start will not be skipped by sampling or linked_flag config. `true` is shorthand for { sampling: true, linked_flag: true }
     */
    startSessionRecording(override?: {
        sampling?: boolean;
        linked_flag?: boolean;
        url_trigger?: true;
        event_trigger?: true;
    } | true): void;
    /**
     * turns session recording off, and updates the config option
     * disable_session_recording to true
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // Stop session recording
     * posthog.stopSessionRecording()
     * ```
     */
    stopSessionRecording(): void;
    /**
     * returns a boolean indicating whether session recording
     * is currently running
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // Stop session recording if it's running
     * if (posthog.sessionRecordingStarted()) {
     *   posthog.stopSessionRecording()
     * }
     * ```
     */
    sessionRecordingStarted(): boolean;
    /**
     * Capture a caught exception manually
     *
     * {@label Error tracking}
     *
     * @public
     *
     * @example
     * ```js
     * // Capture a caught exception
     * try {
     *   // something that might throw
     * } catch (error) {
     *   posthog.captureException(error)
     * }
     * ```
     *
     * @example
     * ```js
     * // With additional properties
     * posthog.captureException(error, {
     *   customProperty: 'value',
     *   anotherProperty: ['I', 'can be a list'],
     *   ...
     * })
     * ```
     *
     * @param {Error} error The error to capture
     * @param {Object} [additionalProperties] Any additional properties to add to the error event
     * @returns {CaptureResult} The result of the capture
     */
    captureException(error: unknown, additionalProperties?: Properties): CaptureResult | undefined;
    /**
     * returns a boolean indicating whether the [toolbar](/docs/toolbar) loaded
     *
     * {@label Toolbar}
     *
     * @public
     *
     * @param toolbarParams
     * @returns {boolean} Whether the toolbar loaded
     */
    loadToolbar(params: ToolbarParams): boolean;
    /**
     * Returns the value of a super property. Returns undefined if the property doesn't exist.
     *
     * {@label Identification}
     *
     * @remarks
     * get_property() can only be called after the PostHog library has finished loading.
     * init() has a loaded function available to handle this automatically.
     *
     * @example
     * ```js
     * // grab value for '$user_id' after the posthog library has loaded
     * posthog.init('<YOUR PROJECT TOKEN>', {
     *     loaded: function(posthog) {
     *         user_id = posthog.get_property('$user_id');
     *     }
     * });
     * ```
     * @public
     *
     * @param {String} property_name The name of the super property you want to retrieve
     */
    get_property(property_name: string): Property | undefined;
    /**
     * Returns the value of the session super property named property_name. If no such
     * property is set, getSessionProperty() will return the undefined value.
     *
     * {@label Identification}
     *
     * @remarks
     * This is based on browser-level `sessionStorage`, NOT the PostHog session.
     * getSessionProperty() can only be called after the PostHog library has finished loading.
     * init() has a loaded function available to handle this automatically.
     *
     * @example
     * ```js
     * // grab value for 'user_id' after the posthog library has loaded
     * posthog.init('YOUR PROJECT TOKEN', {
     *     loaded: function(posthog) {
     *         user_id = posthog.getSessionProperty('user_id');
     *     }
     * });
     * ```
     *
     * @param {String} property_name The name of the session super property you want to retrieve
     */
    getSessionProperty(property_name: string): Property | undefined;
    /**
     * Returns a string representation of the PostHog instance.
     *
     * {@label Initialization}
     *
     * @internal
     */
    toString(): string;
    _isIdentified(): boolean;
    _hasPersonProcessing(): boolean;
    _shouldCapturePageleave(): boolean;
    /**
     *  Creates a person profile for the current user, if they don't already have one and config.person_profiles is set
     *  to 'identified_only'. Produces a warning and does not create a profile if config.person_profiles is set to
     *  'never'. Learn more about [person profiles](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @public
     *
     * @example
     * ```js
     * posthog.createPersonProfile()
     * ```
     */
    createPersonProfile(): void;
    /**
     * Enables person processing if possible, returns true if it does so or already enabled, false otherwise
     *
     * @param function_name
     */
    _requirePersonProcessing(function_name: string): boolean;
    private _is_persistence_disabled;
    private _sync_opt_out_with_persistence;
    /**
     * Opts the user into data capturing and persistence.
     *
     * {@label Privacy}
     *
     * @remarks
     * Enables event tracking and data persistence (cookies/localStorage) for this PostHog instance.
     * By default, captures an `$opt_in` event unless disabled.
     *
     * @example
     * ```js
     * // simple opt-in
     * posthog.opt_in_capturing()
     * ```
     *
     * @example
     * ```js
     * // opt-in with custom event and properties
     * posthog.opt_in_capturing({
     *     captureEventName: 'Privacy Accepted',
     *     captureProperties: { source: 'banner' }
     * })
     * ```
     *
     * @example
     * ```js
     * // opt-in without capturing event
     * posthog.opt_in_capturing({
     *     captureEventName: false
     * })
     * ```
     *
     * @public
     *
     * @param {Object} [config] A dictionary of config options to override
     * @param {string} [config.capture_event_name=$opt_in] Event name to be used for capturing the opt-in action. Set to `null` or `false` to skip capturing the optin event
     * @param {Object} [config.capture_properties] Set of properties to be captured along with the opt-in action
     */
    opt_in_capturing(options?: {
        captureEventName?: EventName | null | false; /** event name to be used for capturing the opt-in action */
        captureProperties?: Properties; /** set of properties to be captured along with the opt-in action */
    }): void;
    /**
     * Opts the user out of data capturing and persistence.
     *
     * {@label Privacy}
     *
     * @remarks
     * Disables event tracking and data persistence (cookies/localStorage) for this PostHog instance.
     * If `opt_out_persistence_by_default` is true, SDK persistence will also be disabled.
     *
     * @example
     * ```js
     * // opt user out (e.g., on privacy settings page)
     * posthog.opt_out_capturing()
     * ```
     *
     * @public
     */
    opt_out_capturing(): void;
    /**
     * Checks if the user has opted into data capturing.
     *
     * {@label Privacy}
     *
     * @remarks
     * Returns the current consent status for event tracking and data persistence.
     *
     * @example
     * ```js
     * if (posthog.has_opted_in_capturing()) {
     *     // show analytics features
     * }
     * ```
     *
     * @public
     *
     * @returns {boolean} current opt-in status
     */
    has_opted_in_capturing(): boolean;
    /**
     * Checks if the user has opted out of data capturing.
     *
     * {@label Privacy}
     *
     * @remarks
     * Returns the current consent status for event tracking and data persistence.
     *
     * @example
     * ```js
     * if (posthog.has_opted_out_capturing()) {
     *     // disable analytics features
     * }
     * ```
     *
     * @public
     *
     * @returns {boolean} current opt-out status
     */
    has_opted_out_capturing(): boolean;
    /**
     * Checks whether the PostHog library is currently capturing events.
     *
     * Usually this means that the user has not opted out of capturing, but the exact behaviour can be controlled by
     * some config options.
     *
     * Additionally, if the cookieless_mode is set to 'on_reject', we will capture events in cookieless mode if the
     * user has explicitly opted out.
     *
     * {@label Privacy}
     *
     * @see {PostHogConfig.cookieless_mode}
     * @see {PostHogConfig.opt_out_persistence_by_default}
     * @see {PostHogConfig.respect_dnt}
     *
     * @returns {boolean} whether the posthog library is capturing events
     */
    is_capturing(): boolean;
    /**
     * Clear the user's opt in/out status of data capturing and cookies/localstorage for this PostHog instance
     *
     * {@label Privacy}
     *
     * @public
     *
     */
    clear_opt_in_out_capturing(): void;
    _is_bot(): boolean | undefined;
    _captureInitialPageview(): void;
    /**
     * Enables or disables debug mode for detailed logging.
     *
     * @remarks
     * Debug mode logs all PostHog calls to the browser console for troubleshooting.
     * Can also be enabled by adding `?__posthog_debug=true` to the URL.
     *
     * {@label Initialization}
     *
     * @example
     * ```js
     * // enable debug mode
     * posthog.debug(true)
     * ```
     *
     * @example
     * ```js
     * // disable debug mode
     * posthog.debug(false)
     * ```
     *
     * @public
     *
     * @param {boolean} [debug] If true, will enable debug mode.
     */
    debug(debug?: boolean): void;
    /**
     * Helper method to check if external API calls (flags/decide) should be disabled
     * Handles migration from old `advanced_disable_decide` to new `advanced_disable_flags`
     */
    _shouldDisableFlags(): boolean;
    private _runBeforeSend;
    /**
     * Returns the current page view ID.
     *
     * {@label Initialization}
     *
     * @public
     *
     * @returns {string} The current page view ID
     */
    getPageViewId(): string | undefined;
    /**
     * Capture written user feedback for a LLM trace. Numeric values are converted to strings.
     *
     * {@label LLM analytics}
     *
     * @public
     *
     * @param traceId The trace ID to capture feedback for.
     * @param userFeedback The feedback to capture.
     */
    captureTraceFeedback(traceId: string | number, userFeedback: string): void;
    /**
     * Capture a metric for a LLM trace. Numeric values are converted to strings.
     *
     * {@label LLM analytics}
     *
     * @public
     *
     * @param traceId The trace ID to capture the metric for.
     * @param metricName The name of the metric to capture.
     * @param metricValue The value of the metric to capture.
     */
    captureTraceMetric(traceId: string | number, metricName: string, metricValue: string | number | boolean): void;
}

declare const posthog: PostHog;

export { type ActionStepStringMatching, type ActionStepType, type AutocaptureCompatibleElement, type AutocaptureConfig, type BasicSurveyQuestion, type BeforeSendFn, type BootstrapConfig, type Breaker, COPY_AUTOCAPTURE_EVENT, type CaptureOptions, type CaptureResult, type CapturedNetworkRequest, Compression, type ConfigDefaults, type DeadClickCandidate, type DeadClicksAutoCaptureConfig, type DomAutocaptureEvents, type EarlyAccessFeature, type EarlyAccessFeatureCallback, type EarlyAccessFeatureResponse, type EarlyAccessFeatureStage, type ErrorEventArgs, type ErrorTrackingOptions, type ErrorTrackingSuppressionRule, type ErrorTrackingSuppressionRuleValue, type EvaluationReason, type EventHandler, type EventName, type ExceptionAutoCaptureConfig, type ExternalIntegrationKind, type FeatureFlagDetail, type FeatureFlagMetadata, type FeatureFlagsCallback, type FlagVariant, type FlagsResponse, type Headers, type HeatmapConfig, type InitiatorType, type JsonRecord, type JsonType, type KnownEventName, type LinkSurveyQuestion, type MultipleSurveyQuestion, type NetworkRecordOptions, type NetworkRequest, type PerformanceCaptureConfig, type PersistentStore, PostHog, type PostHogConfig, type Properties, type Property, type PropertyMatchType, type QueuedRequestWithOptions, type RatingSurveyQuestion, type RemoteConfig, type RemoteConfigFeatureFlagCallback, type RequestCallback, type RequestQueueConfig, type RequestResponse, type RequestWithOptions, type RetriableRequestWithOptions, type SessionIdChangedCallback, type SessionRecordingCanvasOptions, type SessionRecordingOptions, type SessionRecordingUrlTrigger, type SeverityLevel, type SiteApp, type SiteAppGlobals, type SiteAppLoader, type SnippetArrayItem, type SupportedWebVitalsMetrics, type Survey, type SurveyActionType, type SurveyAppearance, type SurveyCallback, type SurveyElement, SurveyEventName, SurveyEventProperties, SurveyPosition, type SurveyQuestion, SurveyQuestionBranchingType, type SurveyQuestionDescriptionContentType, SurveyQuestionType, type SurveyRenderReason, SurveySchedule, SurveyType, SurveyWidgetType, type SurveyWithTypeAndAppearance, type ToolbarParams, type ToolbarSource, type ToolbarUserIntent, type ToolbarVersion, posthog as default, posthog, severityLevels };
