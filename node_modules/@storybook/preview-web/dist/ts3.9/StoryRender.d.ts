import { AnyFramework, StoryId, ViewMode, StoryContextForLoaders } from '@storybook/csf';
import { Story, RenderContext, StoryStore } from '@storybook/store';
import { Channel } from '@storybook/addons';
export declare type RenderPhase = 'preparing' | 'loading' | 'rendering' | 'playing' | 'played' | 'completed' | 'aborted' | 'errored';
export declare type RenderContextCallbacks<TFramework extends AnyFramework> = Pick<RenderContext<TFramework>, 'showMain' | 'showError' | 'showException'>;
export declare const PREPARE_ABORTED: Error;
export interface Render<TFramework extends AnyFramework> {
    id: StoryId;
    story?: Story<TFramework>;
    isPreparing: () => boolean;
    disableKeyListeners: boolean;
    teardown: (options: {
        viewModeChanged: boolean;
    }) => Promise<void>;
    renderToElement: (canvasElement: HTMLElement, renderStoryToElement?: any) => Promise<void>;
}
export declare class StoryRender<TFramework extends AnyFramework> implements Render<TFramework> {
    channel: Channel;
    store: StoryStore<TFramework>;
    private renderToScreen;
    private callbacks;
    id: StoryId;
    viewMode: ViewMode;
    story?: Story<TFramework>;
    phase?: RenderPhase;
    private abortController?;
    private canvasElement?;
    private notYetRendered;
    disableKeyListeners: boolean;
    constructor(channel: Channel, store: StoryStore<TFramework>, renderToScreen: (renderContext: RenderContext<TFramework>, canvasElement: HTMLElement) => void | Promise<void>, callbacks: RenderContextCallbacks<TFramework>, id: StoryId, viewMode: ViewMode, story?: Story<TFramework>);
    private runPhase;
    prepare(): Promise<void>;
    isEqual(other?: Render<TFramework>): boolean;
    isPreparing(): boolean;
    isPending(): boolean;
    context(): Pick<StoryContextForLoaders<TFramework, import("@storybook/csf").Args>, string | number>;
    renderToElement(canvasElement: HTMLElement): Promise<void>;
    render({ initial, forceRemount, }?: {
        initial?: boolean;
        forceRemount?: boolean;
    }): Promise<void>;
    rerender(): Promise<void>;
    remount(): Promise<void>;
    cancelRender(): void;
    teardown(options?: {}): Promise<void>;
}
