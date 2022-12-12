/// <reference types="webpack-env" />
import { ClientApi } from '@storybook/client-api';
import type { AnyFramework, ArgsStoryFn } from '@storybook/csf';
import type { WebProjectAnnotations } from '@storybook/store';
import { Loadable } from './types';
export declare function start<TFramework extends AnyFramework>(renderToDOM: WebProjectAnnotations<TFramework>['renderToDOM'], { decorateStory, render, }?: {
    decorateStory?: WebProjectAnnotations<TFramework>['applyDecorators'];
    render?: ArgsStoryFn<TFramework>;
}): {
    forceReRender: () => never;
    getStorybook: () => never;
    configure: () => never;
    clientApi: {
        addDecorator: () => never;
        addParameters: () => never;
        clearDecorators: () => never;
        addLoader: () => never;
        setAddon: () => never;
        getStorybook: () => never;
        storiesOf: () => never;
        raw: () => never;
    };
    raw?: undefined;
} | {
    forceReRender: () => void;
    getStorybook: () => void[];
    raw: () => void;
    clientApi: ClientApi<TFramework>;
    configure(framework: string, loadable: Loadable, m?: NodeModule, showDeprecationWarning?: boolean): void;
};
