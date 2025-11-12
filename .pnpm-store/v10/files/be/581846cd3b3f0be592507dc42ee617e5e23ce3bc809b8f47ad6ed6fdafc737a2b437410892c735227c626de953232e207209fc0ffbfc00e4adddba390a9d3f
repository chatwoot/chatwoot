import { PostHogConfig, Properties } from './types';
/**
 * PostHog Persistence Object
 * @constructor
 */
export declare class PostHogPersistence {
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
