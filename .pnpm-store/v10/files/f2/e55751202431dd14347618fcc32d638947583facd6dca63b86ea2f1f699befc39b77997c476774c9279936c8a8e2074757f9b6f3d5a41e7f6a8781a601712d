import type { FeedbackInternalOptions, FeedbackModalIntegration } from '@sentry/types';
import type { ComponentType, h as hType } from 'preact';
import type * as Hooks from 'preact/hooks';
interface FactoryParams {
    h: typeof hType;
    hooks: typeof Hooks;
    imageBuffer: HTMLCanvasElement;
    dialog: ReturnType<FeedbackModalIntegration['createDialog']>;
    options: FeedbackInternalOptions;
}
interface Props {
    onError: (error: Error) => void;
}
export declare function ScreenshotEditorFactory({ h, hooks, imageBuffer, dialog, options, }: FactoryParams): ComponentType<Props>;
export {};
//# sourceMappingURL=ScreenshotEditor.d.ts.map