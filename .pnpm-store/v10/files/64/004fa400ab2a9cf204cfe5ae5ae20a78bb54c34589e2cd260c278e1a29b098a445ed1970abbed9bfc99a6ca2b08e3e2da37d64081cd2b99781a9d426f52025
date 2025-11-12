import type { StoryProps, VariantProps, Story, Variant, Awaitable } from '@histoire/shared';
export interface App {
    el: HTMLElement;
    onMount?: () => void;
    onUpdate?: () => void;
    onUnmount?: () => void;
}
export interface MountApi {
    el: HTMLElement;
    state: Record<string, any>;
    onUpdate: (cb: () => unknown) => Awaitable<void>;
    onUnmount: (cb: () => unknown) => Awaitable<void>;
}
export interface VanillaApi {
    onMount?: (api: MountApi) => Awaitable<void>;
    onMountControls?: (api: MountApi) => Awaitable<void>;
}
interface CommonProps {
    setupApp?: (payload: {
        app: App;
        story: Story;
        variant: Variant;
    }) => unknown;
}
export type StoryOptions = Omit<StoryProps, 'setupApp'> & CommonProps & ((VanillaApi & {
    variants?: never;
}) | {
    variants?: VariantOptions[];
    onMount?: never;
    onMountControls?: never;
});
export interface VariantOptions extends Omit<VariantProps, 'setupApp'>, CommonProps, VanillaApi {
}
export declare function defineStory(story: StoryOptions): StoryOptions;
export {};
