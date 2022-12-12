import { ReactNode } from 'react';
import { Channel } from '@storybook/channels';
import { ThemeVars } from '@storybook/theming';
import { API, State, ModuleFn, Root, Group, Story } from '../index';
import { StoryMapper, Refs } from './refs';
import { UIOptions } from './layout';
interface SidebarOptions {
    showRoots?: boolean;
    collapsedRoots?: string[];
    renderLabel?: (item: Root | Group | Story) => ReactNode;
}
declare type IframeRenderer = (storyId: string, viewMode: State['viewMode'], id: string, baseUrl: string, scale: number, queryParams: Record<string, any>) => ReactNode;
export interface Provider {
    channel?: Channel;
    serverChannel?: Channel;
    renderPreview?: IframeRenderer;
    handleAPI(api: API): void;
    getConfig(): {
        sidebar?: SidebarOptions;
        theme?: ThemeVars;
        refs?: Refs;
        StoryMapper?: StoryMapper;
        [k: string]: any;
    } & Partial<UIOptions>;
    [key: string]: any;
}
export interface SubAPI {
    renderPreview?: Provider['renderPreview'];
}
export declare const init: ModuleFn;
export {};
