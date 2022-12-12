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
Object.defineProperty(exports, "__esModule", { value: true });
var bindReporter_1 = require("./lib/bindReporter");
var initMetric_1 = require("./lib/initMetric");
var observe_1 = require("./lib/observe");
var onHidden_1 = require("./lib/onHidden");
exports.getCLS = function (onReport, reportAllChanges) {
    var metric = initMetric_1.initMetric('CLS', 0);
    var report;
    var sessionValue = 0;
    var sessionEntries = [];
    var entryHandler = function (entry) {
        // Only count layout shifts without recent user input.
        // TODO: Figure out why entry can be undefined
        if (entry && !entry.hadRecentInput) {
            var firstSessionEntry = sessionEntries[0];
            var lastSessionEntry = sessionEntries[sessionEntries.length - 1];
            // If the entry occurred less than 1 second after the previous entry and
            // less than 5 seconds after the first entry in the session, include the
            // entry in the current session. Otherwise, start a new session.
            if (sessionValue &&
                sessionEntries.length !== 0 &&
                entry.startTime - lastSessionEntry.startTime < 1000 &&
                entry.startTime - firstSessionEntry.startTime < 5000) {
                sessionValue += entry.value;
                sessionEntries.push(entry);
            }
            else {
                sessionValue = entry.value;
                sessionEntries = [entry];
            }
            // If the current session value is larger than the current CLS value,
            // update CLS and the entries contributing to it.
            if (sessionValue > metric.value) {
                metric.value = sessionValue;
                metric.entries = sessionEntries;
                if (report) {
                    report();
                }
            }
        }
    };
    var po = observe_1.observe('layout-shift', entryHandler);
    if (po) {
        report = bindReporter_1.bindReporter(onReport, metric, reportAllChanges);
        onHidden_1.onHidden(function () {
            po.takeRecords().map(entryHandler);
            report(true);
        });
    }
};
//# sourceMappingURL=getCLS.js.map