/*
 * Copyright 2024 Google LLC
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

import {getInteractionCount} from './polyfills/interactionCountPolyfill.js';

interface Interaction {
  id: number;
  latency: number;
  entries: PerformanceEventTiming[];
}

interface EntryPreProcessingHook {
  (entry: PerformanceEventTiming): void;
}

// A list of longest interactions on the page (by latency) sorted so the
// longest one is first. The list is at most MAX_INTERACTIONS_TO_CONSIDER long.
export const longestInteractionList: Interaction[] = [];

// A mapping of longest interactions by their interaction ID.
// This is used for faster lookup.
export const longestInteractionMap: Map<number, Interaction> = new Map();

// The default `durationThreshold` used across this library for observing
// `event` entries via PerformanceObserver.
export const DEFAULT_DURATION_THRESHOLD = 40;

// Used to store the interaction count after a bfcache restore, since p98
// interaction latencies should only consider the current navigation.
let prevInteractionCount = 0;

/**
 * Returns the interaction count since the last bfcache restore (or for the
 * full page lifecycle if there were no bfcache restores).
 */
const getInteractionCountForNavigation = () => {
  return getInteractionCount() - prevInteractionCount;
};

export const resetInteractions = () => {
  prevInteractionCount = getInteractionCount();
  longestInteractionList.length = 0;
  longestInteractionMap.clear();
};

/**
 * Returns the estimated p98 longest interaction based on the stored
 * interaction candidates and the interaction count for the current page.
 */
export const estimateP98LongestInteraction = () => {
  const candidateInteractionIndex = Math.min(
    longestInteractionList.length - 1,
    Math.floor(getInteractionCountForNavigation() / 50),
  );

  return longestInteractionList[candidateInteractionIndex];
};

// To prevent unnecessary memory usage on pages with lots of interactions,
// store at most 10 of the longest interactions to consider as INP candidates.
const MAX_INTERACTIONS_TO_CONSIDER = 10;

/**
 * A list of callback functions to run before each entry is processed.
 * Exposing this list allows the attribution build to hook into the
 * entry processing pipeline.
 */
export const entryPreProcessingCallbacks: EntryPreProcessingHook[] = [];

/**
 * Takes a performance entry and adds it to the list of worst interactions
 * if its duration is long enough to make it among the worst. If the
 * entry is part of an existing interaction, it is merged and the latency
 * and entries list is updated as needed.
 */
export const processInteractionEntry = (entry: PerformanceEventTiming) => {
  entryPreProcessingCallbacks.forEach((cb) => cb(entry));

  // Skip further processing for entries that cannot be INP candidates.
  if (!(entry.interactionId || entry.entryType === 'first-input')) return;

  // The least-long of the 10 longest interactions.
  const minLongestInteraction =
    longestInteractionList[longestInteractionList.length - 1];

  const existingInteraction = longestInteractionMap.get(entry.interactionId!);

  // Only process the entry if it's possibly one of the ten longest,
  // or if it's part of an existing interaction.
  if (
    existingInteraction ||
    longestInteractionList.length < MAX_INTERACTIONS_TO_CONSIDER ||
    entry.duration > minLongestInteraction.latency
  ) {
    // If the interaction already exists, update it. Otherwise create one.
    if (existingInteraction) {
      // If the new entry has a longer duration, replace the old entries,
      // otherwise add to the array.
      if (entry.duration > existingInteraction.latency) {
        existingInteraction.entries = [entry];
        existingInteraction.latency = entry.duration;
      } else if (
        entry.duration === existingInteraction.latency &&
        entry.startTime === existingInteraction.entries[0].startTime
      ) {
        existingInteraction.entries.push(entry);
      }
    } else {
      const interaction = {
        id: entry.interactionId!,
        latency: entry.duration,
        entries: [entry],
      };
      longestInteractionMap.set(interaction.id, interaction);
      longestInteractionList.push(interaction);
    }

    // Sort the entries by latency (descending) and keep only the top ten.
    longestInteractionList.sort((a, b) => b.latency - a.latency);
    if (longestInteractionList.length > MAX_INTERACTIONS_TO_CONSIDER) {
      longestInteractionList
        .splice(MAX_INTERACTIONS_TO_CONSIDER)
        .forEach((i) => longestInteractionMap.delete(i.id));
    }
  }
};
