import { VNode } from 'preact';
import { PostHog } from '../../posthog-core';
import { MultipleSurveyQuestion, Survey, SurveyAppearance, SurveyPosition, SurveyQuestion, SurveyType, SurveyWidgetType } from '../../posthog-surveys-types';
export declare function getFontFamily(fontFamily?: string): string;
export declare function getSurveyResponseKey(questionId: string): string;
export declare const defaultSurveyAppearance: {
    readonly fontFamily: "inherit";
    readonly backgroundColor: "#eeeded";
    readonly submitButtonColor: "black";
    readonly submitButtonTextColor: "white";
    readonly ratingButtonColor: "white";
    readonly ratingButtonActiveColor: "black";
    readonly borderColor: "#c9c6c6";
    readonly placeholder: "Start typing...";
    readonly whiteLabel: false;
    readonly displayThankYouMessage: true;
    readonly thankYouMessageHeader: "Thank you for your feedback!";
    readonly position: SurveyPosition.Right;
    readonly widgetType: SurveyWidgetType.Tab;
    readonly widgetLabel: "Feedback";
    readonly widgetColor: "black";
    readonly zIndex: "2147483647";
    readonly disabledButtonOpacity: "0.6";
    readonly maxWidth: "300px";
    readonly textSubtleColor: "#939393";
    readonly boxPadding: "20px 24px";
    readonly boxShadow: "0 4px 12px rgba(0, 0, 0, 0.15)";
    readonly borderRadius: "10px";
    readonly shuffleQuestions: false;
    readonly surveyPopupDelaySeconds: undefined;
    readonly outlineColor: "rgba(59, 130, 246, 0.8)";
    readonly inputBackground: "white";
    readonly inputTextColor: "#020617";
    readonly scrollbarThumbColor: "var(--ph-survey-border-color)";
    readonly scrollbarTrackColor: "var(--ph-survey-background-color)";
};
export declare const addSurveyCSSVariablesToElement: (element: HTMLElement, type: SurveyType, appearance?: SurveyAppearance | null) => void;
export declare function getSurveyStylesheet(posthog?: PostHog): HTMLStyleElement | null;
export declare const retrieveSurveyShadow: (survey: Pick<Survey, "id" | "appearance" | "type">, posthog?: PostHog, element?: Element) => {
    shadow: ShadowRoot;
    isNewlyCreated: boolean;
};
interface SendSurveyEventArgs {
    responses: Record<string, string | number | string[] | null>;
    survey: Survey;
    surveySubmissionId: string;
    isSurveyCompleted: boolean;
    posthog?: PostHog;
}
export declare const sendSurveyEvent: ({ responses, survey, surveySubmissionId, posthog, isSurveyCompleted, }: SendSurveyEventArgs) => void;
export declare const dismissedSurveyEvent: (survey: Survey, posthog?: PostHog, readOnly?: boolean) => void;
export declare const shuffle: (array: any[]) => any[];
export declare const getDisplayOrderChoices: (question: MultipleSurveyQuestion) => string[];
export declare const getDisplayOrderQuestions: (survey: Survey) => SurveyQuestion[];
export declare const hasEvents: (survey: Pick<Survey, "conditions">) => boolean;
export declare const canActivateRepeatedly: (survey: Pick<Survey, "schedule" | "conditions" | "id" | "current_iteration">) => boolean;
/**
 * getSurveySeen checks local storage for the surveySeen Key a
 * and overrides this value if the survey can be repeatedly activated by its events.
 * @param survey
 */
export declare const getSurveySeen: (survey: Survey) => boolean;
export declare const hasWaitPeriodPassed: (waitPeriodInDays: number | undefined) => boolean;
interface SurveyContextProps {
    isPreviewMode: boolean;
    previewPageIndex: number | undefined;
    onPopupSurveyDismissed: () => void;
    isPopup: boolean;
    onPreviewSubmit: (res: string | string[] | number | null) => void;
    surveySubmissionId: string;
}
export declare const SurveyContext: import("preact").Context<SurveyContextProps>;
export declare const useSurveyContext: () => SurveyContextProps;
interface RenderProps {
    component: VNode<{
        className: string;
    }>;
    children: string;
    renderAsHtml?: boolean;
    style?: React.CSSProperties;
}
export declare const renderChildrenAsTextOrHtml: ({ component, children, renderAsHtml, style }: RenderProps) => VNode<{
    className: string;
}>;
export declare function doesSurveyUrlMatch(survey: Pick<Survey, 'conditions'>): boolean;
export declare function doesSurveyDeviceTypesMatch(survey: Survey): boolean;
export declare function doesSurveyMatchSelector(survey: Survey): boolean;
interface InProgressSurveyState {
    surveySubmissionId: string;
    lastQuestionIndex: number;
    responses: Record<string, string | number | string[] | null>;
}
export declare const setInProgressSurveyState: (survey: Pick<Survey, "id" | "current_iteration">, state: InProgressSurveyState) => void;
export declare const getInProgressSurveyState: (survey: Pick<Survey, "id" | "current_iteration">) => InProgressSurveyState | null;
export declare const isSurveyInProgress: (survey: Pick<Survey, "id" | "current_iteration">) => boolean;
export declare const clearInProgressSurveyState: (survey: Pick<Survey, "id" | "current_iteration">) => void;
export declare function getSurveyContainerClass(survey: Pick<Survey, 'id'>, asSelector?: boolean): string;
export {};
