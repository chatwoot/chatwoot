import { FeedbackModalIntegration, Integration, IntegrationFn } from '@sentry/types';
import { ActorComponent } from './components/Actor';
import { OverrideFeedbackConfiguration } from './types';
type Unsubscribe = () => void;
/**
 * Allow users to capture user feedback and send it to Sentry.
 */
interface BuilderOptions {
    lazyLoadIntegration: (name: 'feedbackModalIntegration' | 'feedbackScreenshotIntegration', scriptNonce?: string) => Promise<IntegrationFn>;
    getModalIntegration?: null | (() => IntegrationFn);
    getScreenshotIntegration?: null | (() => IntegrationFn);
}
export declare const buildFeedbackIntegration: ({ lazyLoadIntegration, getModalIntegration, getScreenshotIntegration, }: BuilderOptions) => IntegrationFn<Integration & {
    attachTo(el: Element | string, optionOverrides?: OverrideFeedbackConfiguration): Unsubscribe;
    createForm(optionOverrides?: OverrideFeedbackConfiguration): Promise<ReturnType<FeedbackModalIntegration['createDialog']>>;
    createWidget(optionOverrides?: OverrideFeedbackConfiguration): ActorComponent;
    remove(): void;
}>;
export {};
//# sourceMappingURL=integration.d.ts.map
