import { BeforeSendFn, KnownEventName } from '../types';
/**
 * Provides an implementation of sampling that samples based on the distinct ID.
 * Using the provided percentage.
 * Can be used to create a beforeCapture fn for a PostHog instance.
 *
 * Setting 0.5 will cause roughly 50% of distinct ids to have events sent.
 * Not 50% of events for each distinct id.
 *
 * @param percent a number from 0 to 1, 1 means always send and, 0 means never send the event
 */
export declare function sampleByDistinctId(percent: number): BeforeSendFn;
/**
 * Provides an implementation of sampling that samples based on the session ID.
 * Using the provided percentage.
 * Can be used to create a beforeCapture fn for a PostHog instance.
 *
 * Setting 0.5 will cause roughly 50% of sessions to have events sent.
 * Not 50% of events for each session.
 *
 * @param percent a number from 0 to 1, 1 means always send and, 0 means never send the event
 */
export declare function sampleBySessionId(percent: number): BeforeSendFn;
/**
 * Provides an implementation of sampling that samples based on the event name.
 * Using the provided percentage.
 * Can be used to create a beforeCapture fn for a PostHog instance.
 *
 * @param eventNames an array of event names to sample, sampling is applied across events not per event name
 * @param percent a number from 0 to 1, 1 means always send, 0 means never send the event
 */
export declare function sampleByEvent(eventNames: KnownEventName[], percent: number): BeforeSendFn;
export declare const printAndDropEverything: BeforeSendFn;
