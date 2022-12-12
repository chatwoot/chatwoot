"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var dompurify_html_1 = require("./dompurify-html");
exports.default = {
    install: function (Vue, config) {
        if (config === void 0) { config = {}; }
        Vue.directive('dompurify-html', (0, dompurify_html_1.buildDirective)(config));
    },
};
