import { PostHog } from '../posthog-core';
import { ToolbarParams } from '../types';
export declare class Toolbar {
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
