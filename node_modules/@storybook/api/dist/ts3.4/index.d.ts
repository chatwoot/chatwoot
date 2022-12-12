import { Component, FunctionComponent, ReactElement, ReactNode } from 'react';
import { Conditional } from '@storybook/csf';
import { RouterData } from '@storybook/router';
import { Listener } from '@storybook/channels';
import Store, { Options } from './store';
import { StoriesHash, Story, Root, Group } from './lib/stories';
import { ComposedRef, Refs } from './modules/refs';
import { isGroup, isRoot, isStory } from './lib/stories';
import * as provider from './modules/provider';
import * as addons from './modules/addons';
import * as channel from './modules/channel';
import * as notifications from './modules/notifications';
import * as settings from './modules/settings';
import * as releaseNotes from './modules/release-notes';
import * as stories from './modules/stories';
import * as refs from './modules/refs';
import * as layout from './modules/layout';
import * as shortcuts from './modules/shortcuts';
import * as url from './modules/url';
import * as version from './modules/versions';
import * as globals from './modules/globals';
declare const ActiveTabs: {
    SIDEBAR: "sidebar";
    CANVAS: "canvas";
    ADDONS: "addons";
};
export { default as merge } from './lib/merge';
export { Options as StoreOptions, Listener as ChannelListener };
export { ActiveTabs };
export declare type ModuleArgs = RouterData & ProviderData & {
    mode?: 'production' | 'development';
    state: State;
    fullAPI: API;
    store: Store;
};
export declare type State = layout.SubState & stories.SubState & refs.SubState & notifications.SubState & version.SubState & url.SubState & shortcuts.SubState & releaseNotes.SubState & settings.SubState & globals.SubState & RouterData & Other;
export declare type API = addons.SubAPI & channel.SubAPI & provider.SubAPI & stories.SubAPI & refs.SubAPI & globals.SubAPI & layout.SubAPI & notifications.SubAPI & shortcuts.SubAPI & releaseNotes.SubAPI & settings.SubAPI & version.SubAPI & url.SubAPI & Other;
interface Other {
    [key: string]: any;
}
export interface Combo {
    api: API;
    state: State;
}
interface ProviderData {
    provider: provider.Provider;
}
export declare type ManagerProviderProps = RouterData & ProviderData & {
    docsMode: boolean;
    children: ReactNode | ((props: Combo) => ReactNode);
};
export declare type StoryId = string;
export declare type StoryKind = string;
export interface Args {
    [key: string]: any;
}
export interface ArgType {
    name?: string;
    description?: string;
    defaultValue?: any;
    if?: Conditional;
    [key: string]: any;
}
export interface ArgTypes {
    [key: string]: ArgType;
}
export interface Parameters {
    [key: string]: any;
}
export declare const combineParameters: (...parameterSets: Parameters[]) => any;
export declare type ModuleFn = (m: ModuleArgs) => Module;
interface Module {
    init?: () => void;
    api?: unknown;
    state?: unknown;
}
declare class ManagerProvider extends Component<ManagerProviderProps, State> {
    api: API;
    modules: Module[];
    static displayName: string;
    constructor(props: ManagerProviderProps);
    static getDerivedStateFromProps(props: ManagerProviderProps, state: State): {
        location: Partial<Location>;
        path: string;
        refId: string;
        viewMode: string;
        storyId: string;
        layout: layout.Layout;
        ui: layout.UI;
        selectedPanel: string;
        theme: import("@storybook/theming").ThemeVars;
        storiesHash: StoriesHash;
        storiesConfigured: boolean;
        storiesFailed?: Error;
        refs: Record<string, ComposedRef>;
        notifications: notifications.Notification[];
        versions: version.Versions & version.UnknownEntries;
        lastVersionCheck: number;
        dismissedVersionNotification: string;
        customQueryParams: url.QueryParams;
        shortcuts: shortcuts.Shortcuts;
        releaseNotesViewed: string[];
        settings: settings.Settings;
        globals?: import("@storybook/csf").Globals;
        globalTypes?: import("@storybook/csf").GlobalTypes;
        navigate: (to: string | number, { plain, ...options }?: any) => void;
        singleStory?: boolean;
    };
    shouldComponentUpdate(nextProps: ManagerProviderProps, nextState: State): boolean;
    initModules: () => void;
    render(): JSX.Element;
}
interface ManagerConsumerProps<P = unknown> {
    filter?: (combo: Combo) => P;
    children: FunctionComponent<P> | ReactNode;
}
declare function ManagerConsumer<P = Combo>({ filter, children, }: ManagerConsumerProps<P>): ReactElement;
export declare function useStorybookState(): State;
export declare function useStorybookApi(): API;
export { StoriesHash, Story, Root, Group, ComposedRef, Refs };
export { ManagerConsumer as Consumer, ManagerProvider as Provider, isGroup, isRoot, isStory };
export interface EventMap {
    [eventId: string]: Listener;
}
export declare const useChannel: (eventMap: EventMap, deps?: any[]) => (type: string, ...args: any[]) => void;
export declare function useStoryPrepared(storyId?: StoryId): boolean;
export declare function useParameter<S>(parameterKey: string, defaultValue?: S): S;
declare type StateMerger<S> = (input: S) => S;
export declare function useSharedState<S>(stateId: string, defaultState?: S): [
    S,
    (newStateOrMerger: S | StateMerger<S>, options?: Options) => void
];
export declare function useAddonState<S>(addonId: string, defaultState?: S): [
    S,
    (newStateOrMerger: S | StateMerger<S>, options?: Options) => void
];
export declare function useArgs(): [
    Args,
    (newArgs: Args) => void,
    (argNames?: string[]) => void
];
export declare function useGlobals(): [
    Args,
    (newGlobals: Args) => void
];
export declare function useGlobalTypes(): ArgTypes;
export declare function useArgTypes(): ArgTypes;
