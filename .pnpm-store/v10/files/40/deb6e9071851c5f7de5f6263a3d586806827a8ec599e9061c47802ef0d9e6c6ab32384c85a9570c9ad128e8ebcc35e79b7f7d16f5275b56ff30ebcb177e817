import { PostHog } from '../posthog-core';
import { Survey, SurveyCallback, SurveyWithTypeAndAppearance } from '../posthog-surveys-types';
export declare function getNextSurveyStep(survey: Survey, currentQuestionIndex: number, response: string | string[] | number | null): any;
export declare class SurveyManager {
    private _posthog;
    private _surveyInFocus;
    private _surveyTimeouts;
    private _widgetSelectorListeners;
    constructor(posthog: PostHog);
    private _clearSurveyTimeout;
    private _handlePopoverSurvey;
    private _handleWidget;
    private _removeWidgetSelectorListener;
    private _manageWidgetSelectorListener;
    /**
     * Sorts surveys by their appearance delay in ascending order. If a survey does not have an appearance delay,
     * it is considered to have a delay of 0.
     * @param surveys
     * @returns The surveys sorted by their appearance delay
     */
    private _sortSurveysByAppearanceDelay;
    renderSurvey: (survey: Survey, selector: Element) => void;
    private _isSurveyFeatureFlagEnabled;
    private _isSurveyConditionMatched;
    private _internalFlagCheckSatisfied;
    checkSurveyEligibility(survey: Survey): {
        eligible: boolean;
        reason?: string;
    };
    /**
     * Surveys can be activated by events or actions. This method checks if the survey has events and actions,
     * and if so, it checks if the survey has been activated.
     * @param survey
     */
    private _hasActionOrEventTriggeredSurvey;
    private _checkFlags;
    getActiveMatchingSurveys: (callback: SurveyCallback, forceReload?: boolean) => void;
    callSurveysAndEvaluateDisplayLogic: (forceReload?: boolean) => void;
    private _addSurveyToFocus;
    private _removeSurveyFromDom;
    private _removeSurveyFromFocus;
    getTestAPI(): {
        addSurveyToFocus: (survey: Pick<Survey, "id">) => void;
        removeSurveyFromFocus: (survey: SurveyWithTypeAndAppearance) => void;
        surveyInFocus: string | null;
        surveyTimeouts: Map<string, NodeJS.Timeout>;
        handleWidget: (survey: Survey) => void;
        handlePopoverSurvey: (survey: Survey) => void;
        manageWidgetSelectorListener: (survey: Survey, selector: string) => void;
        sortSurveysByAppearanceDelay: (surveys: Survey[]) => Survey[];
        checkFlags: (survey: Survey) => boolean;
        isSurveyFeatureFlagEnabled: (flagKey: string | null, flagVariant?: string | undefined) => boolean;
    };
}
export declare const renderSurveysPreview: ({ survey, parentElement, previewPageIndex, forceDisableHtml, onPreviewSubmit, positionStyles, }: {
    survey: Survey;
    parentElement: HTMLElement;
    previewPageIndex: number;
    forceDisableHtml?: boolean;
    onPreviewSubmit?: (res: string | string[] | number | null) => void;
    posthog?: PostHog;
    positionStyles?: React.CSSProperties;
}) => void;
export declare const renderFeedbackWidgetPreview: ({ survey, root, forceDisableHtml, }: {
    survey: Survey;
    root: HTMLElement;
    forceDisableHtml?: boolean;
}) => void;
export declare function generateSurveys(posthog: PostHog, isSurveysEnabled: boolean | undefined): SurveyManager | undefined;
type UseHideSurveyOnURLChangeProps = {
    survey: Pick<Survey, 'id' | 'conditions' | 'type' | 'appearance'>;
    removeSurveyFromFocus?: (survey: SurveyWithTypeAndAppearance) => void;
    setSurveyVisible: (visible: boolean) => void;
    isPreviewMode?: boolean;
};
/**
 * This hook handles URL-based survey visibility after the initial mount.
 * The initial URL check is handled by the `getActiveMatchingSurveys` method in  the `PostHogSurveys` class,
 * which ensures the URL matches before displaying a survey for the first time.
 * That is the method that is called every second to see if there's a matching survey.
 *
 * This separation of concerns means:
 * 1. Initial URL matching is done by `getActiveMatchingSurveys` before displaying the survey
 * 2. Subsequent URL changes are handled here to hide the survey as the user navigates
 */
export declare function useHideSurveyOnURLChange({ survey, removeSurveyFromFocus, setSurveyVisible, isPreviewMode, }: UseHideSurveyOnURLChangeProps): void;
export declare function usePopupVisibility(survey: Survey, posthog: PostHog | undefined, millisecondDelay: number, isPreviewMode: boolean, removeSurveyFromFocus: (survey: SurveyWithTypeAndAppearance) => void, surveyContainerRef?: React.RefObject<HTMLDivElement>): {
    isPopupVisible: boolean;
    isSurveySent: boolean;
    setIsPopupVisible: import("preact/hooks").StateUpdater<boolean>;
    hidePopupWithViewTransition: () => void;
};
interface SurveyPopupProps {
    survey: Survey;
    forceDisableHtml?: boolean;
    posthog?: PostHog;
    style?: React.CSSProperties;
    previewPageIndex?: number | undefined;
    removeSurveyFromFocus?: (survey: SurveyWithTypeAndAppearance) => void;
    isPopup?: boolean;
    onPreviewSubmit?: (res: string | string[] | number | null) => void;
    onPopupSurveyDismissed?: () => void;
    onCloseConfirmationMessage?: () => void;
}
export declare function SurveyPopup({ survey, forceDisableHtml, posthog, style, previewPageIndex, removeSurveyFromFocus, isPopup, onPreviewSubmit, onPopupSurveyDismissed, onCloseConfirmationMessage, }: SurveyPopupProps): JSX.Element | null;
export declare function Questions({ survey, forceDisableHtml, posthog, }: {
    survey: Survey;
    forceDisableHtml: boolean;
    posthog?: PostHog;
}): JSX.Element | null;
export declare function FeedbackWidget({ survey, forceDisableHtml, posthog, readOnly, }: {
    survey: Survey;
    forceDisableHtml?: boolean;
    posthog?: PostHog;
    readOnly?: boolean;
}): JSX.Element | null;
export {};
