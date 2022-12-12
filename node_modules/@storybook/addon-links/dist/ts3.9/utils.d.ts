import type { StoryId, StoryName, ComponentTitle } from '@storybook/csf';
interface ParamsId {
    storyId: StoryId;
}
interface ParamsCombo {
    kind?: ComponentTitle;
    story?: StoryName;
}
export declare const navigate: (params: ParamsId | ParamsCombo) => void;
export declare const hrefTo: (title: ComponentTitle, name: StoryName) => Promise<string>;
export declare const linkTo: (idOrTitle: string, nameInput?: string | ((...args: any[]) => string)) => (...args: any[]) => void;
export declare const withLinks: (...args: any) => any;
export {};
