import { BasicSurveyQuestion, LinkSurveyQuestion, MultipleSurveyQuestion, RatingSurveyQuestion, SurveyAppearance } from '../../../posthog-surveys-types';
export interface CommonQuestionProps {
    forceDisableHtml: boolean;
    appearance: SurveyAppearance;
    onSubmit: (res: string | string[] | number | null) => void;
    onPreviewSubmit: (res: string | string[] | number | null) => void;
    initialValue?: string | string[] | number | null;
    displayQuestionIndex: number;
}
export declare function OpenTextQuestion({ question, forceDisableHtml, appearance, onSubmit, onPreviewSubmit, displayQuestionIndex, initialValue, }: CommonQuestionProps & {
    question: BasicSurveyQuestion;
}): JSX.Element;
export declare function LinkQuestion({ question, forceDisableHtml, appearance, onSubmit, onPreviewSubmit, }: CommonQuestionProps & {
    question: LinkSurveyQuestion;
}): JSX.Element;
export declare function RatingQuestion({ question, forceDisableHtml, displayQuestionIndex, appearance, onSubmit, onPreviewSubmit, initialValue, }: CommonQuestionProps & {
    question: RatingSurveyQuestion;
}): JSX.Element;
export declare function RatingButton({ num, active, displayQuestionIndex, setActiveNumber, }: {
    num: number;
    active: boolean;
    displayQuestionIndex: number;
    appearance: SurveyAppearance;
    setActiveNumber: (num: number) => void;
}): JSX.Element;
export declare function MultipleChoiceQuestion({ question, forceDisableHtml, displayQuestionIndex, appearance, onSubmit, onPreviewSubmit, initialValue, }: CommonQuestionProps & {
    question: MultipleSurveyQuestion;
}): JSX.Element;
