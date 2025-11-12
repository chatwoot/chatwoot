/**
 * Having Survey types in types.ts was confusing tsc
 * and generating an invalid module.d.ts
 * See https://github.com/PostHog/posthog-js/issues/698
 */
import type { PropertyMatchType } from './types';
export declare enum SurveyWidgetType {
    Button = "button",
    Tab = "tab",
    Selector = "selector"
}
export declare enum SurveyPosition {
    TopLeft = "top_left",
    TopRight = "top_right",
    TopCenter = "top_center",
    MiddleLeft = "middle_left",
    MiddleRight = "middle_right",
    MiddleCenter = "middle_center",
    Left = "left",
    Center = "center",
    Right = "right",
    NextToTrigger = "next_to_trigger"
}
export interface SurveyAppearance {
    backgroundColor?: string;
    submitButtonColor?: string;
    textColor?: string;
    submitButtonText?: string;
    submitButtonTextColor?: string;
    descriptionTextColor?: string;
    ratingButtonColor?: string;
    ratingButtonActiveColor?: string;
    ratingButtonHoverColor?: string;
    whiteLabel?: boolean;
    autoDisappear?: boolean;
    displayThankYouMessage?: boolean;
    thankYouMessageHeader?: string;
    thankYouMessageDescription?: string;
    thankYouMessageDescriptionContentType?: SurveyQuestionDescriptionContentType;
    thankYouMessageCloseButtonText?: string;
    borderColor?: string;
    position?: SurveyPosition;
    placeholder?: string;
    shuffleQuestions?: boolean;
    surveyPopupDelaySeconds?: number;
    widgetType?: SurveyWidgetType;
    widgetSelector?: string;
    widgetLabel?: string;
    widgetColor?: string;
    fontFamily?: string;
    maxWidth?: string;
    zIndex?: string;
    disabledButtonOpacity?: string;
    boxPadding?: string;
}
export declare enum SurveyType {
    Popover = "popover",
    API = "api",
    Widget = "widget",
    ExternalSurvey = "external_survey"
}
export type SurveyQuestion = BasicSurveyQuestion | LinkSurveyQuestion | RatingSurveyQuestion | MultipleSurveyQuestion;
export type SurveyQuestionDescriptionContentType = 'html' | 'text';
interface SurveyQuestionBase {
    question: string;
    id?: string;
    description?: string | null;
    descriptionContentType?: SurveyQuestionDescriptionContentType;
    optional?: boolean;
    buttonText?: string;
    branching?: NextQuestionBranching | EndBranching | ResponseBasedBranching | SpecificQuestionBranching;
}
export interface BasicSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.Open;
}
export interface LinkSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.Link;
    link?: string | null;
}
export interface RatingSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.Rating;
    display: 'number' | 'emoji';
    scale: 3 | 5 | 7 | 10;
    lowerBoundLabel: string;
    upperBoundLabel: string;
    skipSubmitButton?: boolean;
}
export interface MultipleSurveyQuestion extends SurveyQuestionBase {
    type: SurveyQuestionType.SingleChoice | SurveyQuestionType.MultipleChoice;
    choices: string[];
    hasOpenChoice?: boolean;
    shuffleOptions?: boolean;
    skipSubmitButton?: boolean;
}
export declare enum SurveyQuestionType {
    Open = "open",
    MultipleChoice = "multiple_choice",
    SingleChoice = "single_choice",
    Rating = "rating",
    Link = "link"
}
export declare enum SurveyQuestionBranchingType {
    NextQuestion = "next_question",
    End = "end",
    ResponseBased = "response_based",
    SpecificQuestion = "specific_question"
}
interface NextQuestionBranching {
    type: SurveyQuestionBranchingType.NextQuestion;
}
interface EndBranching {
    type: SurveyQuestionBranchingType.End;
}
interface ResponseBasedBranching {
    type: SurveyQuestionBranchingType.ResponseBased;
    responseValues: Record<string, any>;
}
interface SpecificQuestionBranching {
    type: SurveyQuestionBranchingType.SpecificQuestion;
    index: number;
}
export type SurveyCallback = (surveys: Survey[], context?: {
    isLoaded: boolean;
    error?: string;
}) => void;
export interface SurveyElement {
    text?: string;
    $el_text?: string;
    tag_name?: string;
    href?: string;
    attr_id?: string;
    attr_class?: string[];
    nth_child?: number;
    nth_of_type?: number;
    attributes?: Record<string, any>;
    event_id?: number;
    order?: number;
    group_id?: number;
}
export interface SurveyRenderReason {
    visible: boolean;
    disabledReason?: string;
}
export declare enum SurveySchedule {
    Once = "once",
    Recurring = "recurring",
    Always = "always"
}
export interface Survey {
    id: string;
    name: string;
    description: string;
    type: SurveyType;
    feature_flag_keys: {
        key: string;
        value?: string;
    }[] | null;
    linked_flag_key: string | null;
    targeting_flag_key: string | null;
    internal_targeting_flag_key: string | null;
    questions: SurveyQuestion[];
    appearance: SurveyAppearance | null;
    conditions: {
        url?: string;
        selector?: string;
        seenSurveyWaitPeriodInDays?: number;
        urlMatchType?: PropertyMatchType;
        events: {
            repeatedActivation?: boolean;
            values: {
                name: string;
            }[];
        } | null;
        actions: {
            values: SurveyActionType[];
        } | null;
        deviceTypes?: string[];
        deviceTypesMatchType?: PropertyMatchType;
        linkedFlagVariant?: string;
    } | null;
    start_date: string | null;
    end_date: string | null;
    current_iteration: number | null;
    current_iteration_start_date: string | null;
    schedule?: SurveySchedule | null;
    enable_partial_responses?: boolean | null;
}
export type SurveyWithTypeAndAppearance = Pick<Survey, 'id' | 'type' | 'appearance'>;
export interface SurveyActionType {
    id: number;
    name: string | null;
    steps?: ActionStepType[];
}
/** Sync with plugin-server/src/types.ts */
export type ActionStepStringMatching = 'contains' | 'exact' | 'regex';
export interface ActionStepType {
    event?: string | null;
    selector?: string | null;
    /** @deprecated Only `selector` should be used now. */
    tag_name?: string;
    text?: string | null;
    /** @default StringMatching.Exact */
    text_matching?: ActionStepStringMatching | null;
    href?: string | null;
    /** @default ActionStepStringMatching.Exact */
    href_matching?: ActionStepStringMatching | null;
    url?: string | null;
    /** @default StringMatching.Contains */
    url_matching?: ActionStepStringMatching | null;
}
export declare enum SurveyEventName {
    SHOWN = "survey shown",
    DISMISSED = "survey dismissed",
    SENT = "survey sent"
}
export declare enum SurveyEventProperties {
    SURVEY_ID = "$survey_id",
    SURVEY_NAME = "$survey_name",
    SURVEY_RESPONSE = "$survey_response",
    SURVEY_ITERATION = "$survey_iteration",
    SURVEY_ITERATION_START_DATE = "$survey_iteration_start_date",
    SURVEY_PARTIALLY_COMPLETED = "$survey_partially_completed",
    SURVEY_SUBMISSION_ID = "$survey_submission_id",
    SURVEY_QUESTIONS = "$survey_questions",
    SURVEY_COMPLETED = "$survey_completed"
}
export {};
