import React from 'react';
import type { StoryId, ComponentTitle, StoryKind, StoryName, Args, ArgTypes, Parameters } from '@storybook/csf';
import type { Provider } from '../modules/provider';
import type { ViewMode } from '../modules/addons';
export type { StoryId };
export interface Root {
    type: 'root';
    id: StoryId;
    depth: 0;
    name: string;
    refId?: string;
    children: StoryId[];
    isComponent: false;
    isRoot: true;
    isLeaf: false;
    renderLabel?: (item: Root) => React.ReactNode;
    startCollapsed?: boolean;
}
export interface Group {
    type: 'group' | 'component';
    id: StoryId;
    depth: number;
    name: string;
    children: StoryId[];
    refId?: string;
    parent?: StoryId;
    isComponent: boolean;
    isRoot: false;
    isLeaf: false;
    renderLabel?: (item: Group) => React.ReactNode;
    parameters?: {
        docsOnly?: boolean;
        viewMode?: ViewMode;
    };
}
export interface Story {
    type: 'story' | 'docs';
    id: StoryId;
    depth: number;
    parent: StoryId;
    name: string;
    kind: StoryKind;
    refId?: string;
    children?: StoryId[];
    isComponent: boolean;
    isRoot: false;
    isLeaf: true;
    renderLabel?: (item: Story) => React.ReactNode;
    prepared: boolean;
    parameters?: {
        fileName: string;
        options: {
            [optionName: string]: any;
        };
        docsOnly?: boolean;
        viewMode?: ViewMode;
        [parameterName: string]: any;
    };
    args?: Args;
    argTypes?: ArgTypes;
    initialArgs?: Args;
}
export interface StoryInput {
    id: StoryId;
    name: string;
    refId?: string;
    kind: StoryKind;
    parameters: {
        fileName: string;
        options: {
            [optionName: string]: any;
        };
        docsOnly?: boolean;
        viewMode?: ViewMode;
        [parameterName: string]: any;
    };
    args?: Args;
    initialArgs?: Args;
}
export interface StoriesHash {
    [id: string]: Root | Group | Story;
}
export declare type StoriesList = (Group | Story)[];
export declare type GroupsList = (Root | Group)[];
export interface StoriesRaw {
    [id: string]: StoryInput;
}
declare type Path = string;
export interface StoryIndexStory {
    id: StoryId;
    name: StoryName;
    title: ComponentTitle;
    importPath: Path;
    parameters?: Parameters;
}
export interface StoryIndex {
    v: number;
    stories: Record<StoryId, StoryIndexStory>;
}
export declare type SetStoriesPayload = {
    v: 2;
    error?: Error;
    globals: Args;
    globalParameters: Parameters;
    stories: StoriesRaw;
    kindParameters: {
        [kind: string]: Parameters;
    };
} | ({
    v?: number;
    stories: StoriesRaw;
} & Record<string, never>);
export declare const denormalizeStoryParameters: ({ globalParameters, kindParameters, stories, }: SetStoriesPayload) => StoriesRaw;
export declare const transformStoryIndexToStoriesHash: (index: StoryIndex, { provider }: {
    provider: Provider;
}) => StoriesHash;
export declare const transformStoriesRawToStoriesHash: (input: StoriesRaw, { provider, prepared }: {
    provider: Provider;
    prepared?: Story['prepared'];
}) => StoriesHash;
export declare type Item = StoriesHash[keyof StoriesHash];
export declare function isRoot(item: Item): item is Root;
export declare function isGroup(item: Item): item is Group;
export declare function isStory(item: Item): item is Story;
export declare const getComponentLookupList: (hash: StoriesHash) => string[][];
export declare const getStoriesLookupList: (hash: StoriesHash) => string[];
