import { RenderContext, RenderContextWithoutStoryContext } from '@storybook/client-api';
export interface PreviewError {
    message?: string;
    stack?: string;
}
export interface RequireContext {
    keys: () => string[];
    (id: string): any;
    resolve(id: string): string;
}
export declare type LoaderFunction = () => void | any[];
export declare type Loadable = RequireContext | RequireContext[] | LoaderFunction;
export type { RenderContext, RenderContextWithoutStoryContext };
export declare type RenderStoryFunction = (context: RenderContext) => void;
