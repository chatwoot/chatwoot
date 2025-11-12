import { PostHog } from '../../posthog-core';
import { SurveyActionType } from '../../posthog-surveys-types';
import { CaptureResult } from '../../types';
export declare class ActionMatcher {
    private readonly _actionRegistry?;
    private readonly _instance?;
    private readonly _actionEvents;
    private _debugEventEmitter;
    constructor(instance?: PostHog);
    init(): void;
    register(actions: SurveyActionType[]): void;
    on(eventName: string, eventPayload?: CaptureResult): void;
    _addActionHook(callback: (actionName: string, eventPayload?: any) => void): void;
    private _checkAction;
    onAction(event: 'actionCaptured', cb: (...args: any[]) => void): () => void;
    private _checkStep;
    private _checkStepEvent;
    private _checkStepUrl;
    private static _matchString;
    private static _escapeStringRegexp;
    private _checkStepElement;
    private _getElementsList;
}
