/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  FirstInputPolyfillEntry,
  FirstInputPolyfillCallback,
} from '../../types.js';

type addOrRemoveEventListener =
  | typeof addEventListener
  | typeof removeEventListener;

let firstInputEvent: Event | null;
let firstInputDelay: number;
let firstInputTimeStamp: Date;
let callbacks: FirstInputPolyfillCallback[];

const listenerOpts: AddEventListenerOptions = {passive: true, capture: true};
const startTimeStamp: Date = new Date();

/**
 * Accepts a callback to be invoked once the first input delay and event
 * are known.
 */
export const firstInputPolyfill = (
  onFirstInput: FirstInputPolyfillCallback,
) => {
  callbacks.push(onFirstInput);
  reportFirstInputDelayIfRecordedAndValid();
};

export const resetFirstInputPolyfill = () => {
  callbacks = [];
  firstInputDelay = -1;
  firstInputEvent = null;
  eachEventType(addEventListener);
};

/**
 * Records the first input delay and event, so subsequent events can be
 * ignored. All added event listeners are then removed.
 */
const recordFirstInputDelay = (delay: number, event: Event) => {
  if (!firstInputEvent) {
    firstInputEvent = event;
    firstInputDelay = delay;
    firstInputTimeStamp = new Date();

    eachEventType(removeEventListener);
    reportFirstInputDelayIfRecordedAndValid();
  }
};

/**
 * Reports the first input delay and event (if they're recorded and valid)
 * by running the array of callback functions.
 */
const reportFirstInputDelayIfRecordedAndValid = () => {
  // In some cases the recorded delay is clearly wrong, e.g. it's negative
  // or it's larger than the delta between now and initialization.
  // - https://github.com/GoogleChromeLabs/first-input-delay/issues/4
  // - https://github.com/GoogleChromeLabs/first-input-delay/issues/6
  // - https://github.com/GoogleChromeLabs/first-input-delay/issues/7
  if (
    firstInputDelay >= 0 &&
    // @ts-ignore (subtracting two dates always returns a number)
    firstInputDelay < firstInputTimeStamp - startTimeStamp
  ) {
    const entry = {
      entryType: 'first-input',
      name: firstInputEvent!.type,
      target: firstInputEvent!.target,
      cancelable: firstInputEvent!.cancelable,
      startTime: firstInputEvent!.timeStamp,
      processingStart: firstInputEvent!.timeStamp + firstInputDelay,
    } as FirstInputPolyfillEntry;
    callbacks.forEach(function (callback) {
      callback(entry);
    });
    callbacks = [];
  }
};

/**
 * Handles pointer down events, which are a special case.
 * Pointer events can trigger main or compositor thread behavior.
 * We differentiate these cases based on whether or not we see a
 * 'pointercancel' event, which are fired when we scroll. If we're scrolling
 * we don't need to report input delay since FID excludes scrolling and
 * pinch/zooming.
 */
const onPointerDown = (delay: number, event: Event) => {
  /**
   * Responds to 'pointerup' events and records a delay. If a pointer up event
   * is the next event after a pointerdown event, then it's not a scroll or
   * a pinch/zoom.
   */
  const onPointerUp = () => {
    recordFirstInputDelay(delay, event);
    removePointerEventListeners();
  };

  /**
   * Responds to 'pointercancel' events and removes pointer listeners.
   * If a 'pointercancel' is the next event to fire after a pointerdown event,
   * it means this is a scroll or pinch/zoom interaction.
   */
  const onPointerCancel = () => {
    removePointerEventListeners();
  };

  /**
   * Removes added pointer event listeners.
   */
  const removePointerEventListeners = () => {
    removeEventListener('pointerup', onPointerUp, listenerOpts);
    removeEventListener('pointercancel', onPointerCancel, listenerOpts);
  };

  addEventListener('pointerup', onPointerUp, listenerOpts);
  addEventListener('pointercancel', onPointerCancel, listenerOpts);
};

/**
 * Handles all input events and records the time between when the event
 * was received by the operating system and when it's JavaScript listeners
 * were able to run.
 */
const onInput = (event: Event) => {
  // Only count cancelable events, which should trigger behavior
  // important to the user.
  if (event.cancelable) {
    // In some browsers `event.timeStamp` returns a `DOMTimeStamp` value
    // (epoch time) instead of the newer `DOMHighResTimeStamp`
    // (document-origin time). To check for that we assume any timestamp
    // greater than 1 trillion is a `DOMTimeStamp`, and compare it using
    // the `Date` object rather than `performance.now()`.
    // - https://github.com/GoogleChromeLabs/first-input-delay/issues/4
    const isEpochTime = event.timeStamp > 1e12;
    const now = isEpochTime ? new Date() : performance.now();

    // Input delay is the delta between when the system received the event
    // (e.g. event.timeStamp) and when it could run the callback (e.g. `now`).
    const delay = (now as number) - event.timeStamp;

    if (event.type == 'pointerdown') {
      onPointerDown(delay, event);
    } else {
      recordFirstInputDelay(delay, event);
    }
  }
};

/**
 * Invokes the passed callback const for =  each event type with t =>he
 * `onInput` const and =  `listenerOpts =>`.
 */
const eachEventType = (callback: addOrRemoveEventListener) => {
  const eventTypes = ['mousedown', 'keydown', 'touchstart', 'pointerdown'];
  eventTypes.forEach((type) => callback(type, onInput, listenerOpts));
};
