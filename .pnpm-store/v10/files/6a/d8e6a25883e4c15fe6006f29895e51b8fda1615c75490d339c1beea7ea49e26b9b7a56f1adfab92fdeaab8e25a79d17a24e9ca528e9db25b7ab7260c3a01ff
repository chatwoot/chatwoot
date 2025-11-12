import { PostHog } from './posthog-core';
import { SurveyCallback, SurveyRenderReason } from './posthog-surveys-types';
import { RemoteConfig } from './types';
import { SurveyEventReceiver } from './utils/survey-event-receiver';
export declare class PostHogSurveys {
    private readonly _instance;
    private _isSurveysEnabled?;
    _surveyEventReceiver: SurveyEventReceiver | null;
    private _surveyManager;
    private _isFetchingSurveys;
    private _isInitializingSurveys;
    private _surveyCallbacks;
    constructor(_instance: PostHog);
    onRemoteConfig(response: RemoteConfig): void;
    reset(): void;
    loadIfEnabled(): void;
    /** Helper to finalize survey initialization */
    private _completeSurveyInitialization;
    /** Helper to handle errors during survey loading */
    private _handleSurveyLoadError;
    /**
     * Register a callback that runs when surveys are initialized.
     * ### Usage:
     *
     *     posthog.onSurveysLoaded((surveys) => {
     *         // You can work with all surveys
     *         console.log('All available surveys:', surveys)
     *
     *         // Or get active matching surveys
     *         posthog.getActiveMatchingSurveys((activeMatchingSurveys) => {
     *             if (activeMatchingSurveys.length > 0) {
     *                 posthog.renderSurvey(activeMatchingSurveys[0].id, '#survey-container')
     *             }
     *         })
     *     })
     *
     * @param {Function} callback The callback function will be called when surveys are loaded or updated.
     *                           It receives the array of all surveys and a context object with error status.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    onSurveysLoaded(callback: SurveyCallback): () => void;
    getSurveys(callback: SurveyCallback, forceReload?: boolean): void;
    /** Helper method to notify all registered callbacks */
    private _notifySurveyCallbacks;
    getActiveMatchingSurveys(callback: SurveyCallback, forceReload?: boolean): void;
    private _getSurveyById;
    private _checkSurveyEligibility;
    canRenderSurvey(surveyId: string): SurveyRenderReason;
    canRenderSurveyAsync(surveyId: string, forceReload: boolean): Promise<SurveyRenderReason>;
    renderSurvey(surveyId: string, selector: string): void;
}
