import { Survey } from '../posthog-surveys-types';
import { ActionMatcher } from '../extensions/surveys/action-matcher';
import { PostHog } from '../posthog-core';
import { CaptureResult } from '../types';
export declare class SurveyEventReceiver {
    private readonly _eventToSurveys;
    private readonly _actionToSurveys;
    private _actionMatcher?;
    private readonly _instance?;
    constructor(instance: PostHog);
    register(surveys: Survey[]): void;
    private _setupActionBasedSurveys;
    private _setupEventBasedSurveys;
    onEvent(event: string, eventPayload?: CaptureResult): void;
    onAction(actionName: string): void;
    private _updateActivatedSurveys;
    getSurveys(): string[];
    getEventToSurveys(): Map<string, string[]>;
    _getActionMatcher(): ActionMatcher | null | undefined;
}
