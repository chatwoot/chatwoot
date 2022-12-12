import { AnyFramework, StoryId } from '@storybook/csf';
import { Story, StoryStore } from '@storybook/store';
import { Channel } from '@storybook/addons';
import { Render, StoryRender } from './StoryRender';
import { DocsContextProps } from './types';
export declare class DocsRender<TFramework extends AnyFramework> implements Render<TFramework> {
    private channel;
    private store;
    id: StoryId;
    story: Story<TFramework>;
    private canvasElement?;
    private context?;
    disableKeyListeners: boolean;
    static fromStoryRender<TFramework extends AnyFramework>(storyRender: StoryRender<TFramework>): DocsRender<TFramework>;
    constructor(channel: Channel, store: StoryStore<TFramework>, id: StoryId, story: Story<TFramework>);
    isPreparing(): boolean;
    renderToElement(canvasElement: HTMLElement, renderStoryToElement: DocsContextProps['renderStoryToElement']): Promise<void>;
    render(): Promise<void>;
    rerender(): Promise<void>;
    teardown({ viewModeChanged }?: {
        viewModeChanged?: boolean;
    }): Promise<void>;
}
