import { PostHog } from './posthog-core';
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
export declare class PageViewManager {
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
export {};
