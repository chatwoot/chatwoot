import { Story } from '@storybook/store';
declare const layoutClassMap: {
    readonly centered: "sb-main-centered";
    readonly fullscreen: "sb-main-fullscreen";
    readonly padded: "sb-main-padded";
};
declare type Layout = keyof typeof layoutClassMap | 'none';
declare enum Mode {
    'MAIN' = "MAIN",
    'NOPREVIEW' = "NOPREVIEW",
    'PREPARING_STORY' = "PREPARING_STORY",
    'PREPARING_DOCS' = "PREPARING_DOCS",
    'ERROR' = "ERROR"
}
export declare class WebView {
    currentLayoutClass?: typeof layoutClassMap[keyof typeof layoutClassMap] | null;
    testing: boolean;
    preparingTimeout: ReturnType<typeof setTimeout>;
    constructor();
    prepareForStory(story: Story<any>): HTMLElement;
    storyRoot(): HTMLElement;
    prepareForDocs(): HTMLElement;
    docsRoot(): HTMLElement;
    applyLayout(layout?: Layout): void;
    checkIfLayoutExists(layout: keyof typeof layoutClassMap): void;
    showMode(mode: Mode): void;
    showErrorDisplay({ message, stack }: {
        message?: string;
        stack?: string;
    }): void;
    showNoPreview(): void;
    showPreparingStory({ immediate }?: {
        immediate?: boolean;
    }): void;
    showPreparingDocs(): void;
    showMain(): void;
    showDocs(): void;
    showStory(): void;
    showStoryDuringRender(): void;
}
export {};
