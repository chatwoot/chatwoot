"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setAllPersonProfilePropertiesAsPersonPropertiesForFlags = void 0;
var event_utils_1 = require("../utils/event-utils");
var utils_1 = require("../utils");
var core_1 = require("@posthog/core");
var setAllPersonProfilePropertiesAsPersonPropertiesForFlags = function (posthog) {
    var allProperties = (0, utils_1.extend)({}, (0, event_utils_1.getEventProperties)(posthog.config.mask_personal_data_properties, posthog.config.custom_personal_data_properties), (0, event_utils_1.getCampaignParams)(posthog.config.custom_campaign_params, posthog.config.mask_personal_data_properties, posthog.config.custom_personal_data_properties), (0, event_utils_1.getReferrerInfo)());
    var personProperties = {};
    (0, utils_1.each)(allProperties, function (v, k) {
        if ((0, core_1.includes)(event_utils_1.CAMPAIGN_PARAMS, k) || (0, core_1.includes)(event_utils_1.EVENT_TO_PERSON_PROPERTIES, k)) {
            personProperties[k] = v;
        }
    });
    posthog.setPersonPropertiesForFlags(personProperties);
};
exports.setAllPersonProfilePropertiesAsPersonPropertiesForFlags = setAllPersonProfilePropertiesAsPersonPropertiesForFlags;
//# sourceMappingURL=setAllPersonProfilePropertiesAsPersonPropertiesForFlags.js.map