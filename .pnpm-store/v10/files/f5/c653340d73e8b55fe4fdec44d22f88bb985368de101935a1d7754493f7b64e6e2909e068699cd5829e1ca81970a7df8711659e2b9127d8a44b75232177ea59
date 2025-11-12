import { Autocapture } from './autocapture';
import { ConsentManager } from './consent';
import { DeadClicksAutocapture } from './extensions/dead-clicks-autocapture';
import { ExceptionObserver } from './extensions/exception-autocapture';
import { HistoryAutocapture } from './extensions/history-autocapture';
import { SessionRecording } from './extensions/replay/sessionrecording';
import { SentryIntegration, sentryIntegration, SentryIntegrationOptions } from './extensions/sentry-integration';
import { Toolbar } from './extensions/toolbar';
import { WebVitalsAutocapture } from './extensions/web-vitals';
import { Heatmaps } from './heatmaps';
import { PageViewManager } from './page-view';
import { PostHogExceptions } from './posthog-exceptions';
import { PostHogFeatureFlags } from './posthog-featureflags';
import { PostHogPersistence } from './posthog-persistence';
import { PostHogSurveys } from './posthog-surveys';
import { SurveyCallback, SurveyRenderReason } from './posthog-surveys-types';
import { RateLimiter } from './rate-limiter';
import { RequestQueue } from './request-queue';
import { RetryQueue } from './retry-queue';
import { ScrollManager } from './scroll-manager';
import { SessionPropsManager } from './session-props';
import { SessionIdManager } from './sessionid';
import { SiteApps } from './site-apps';
import { CaptureOptions, CaptureResult, Compression, ConfigDefaults, EarlyAccessFeatureCallback, EarlyAccessFeatureStage, EventName, FeatureFlagsCallback, JsonType, PostHogConfig, Properties, Property, QueuedRequestWithOptions, RemoteConfig, RequestCallback, SessionIdChangedCallback, SnippetArrayItem, ToolbarParams } from './types';
import { RequestRouter } from './utils/request-router';
import { WebExperiments } from './web-experiments';
import { ExternalIntegrations } from './extensions/external-integration';
type OnlyValidKeys<T, Shape> = T extends Shape ? (Exclude<keyof T, keyof Shape> extends never ? T : never) : never;
export declare const defaultConfig: (defaults?: ConfigDefaults) => PostHogConfig;
export declare const configRenames: (origConfig: Partial<PostHogConfig>) => Partial<PostHogConfig>;
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
export declare class PostHog {
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
export declare function init_from_snippet(): void;
export declare function init_as_module(): PostHog;
export {};
