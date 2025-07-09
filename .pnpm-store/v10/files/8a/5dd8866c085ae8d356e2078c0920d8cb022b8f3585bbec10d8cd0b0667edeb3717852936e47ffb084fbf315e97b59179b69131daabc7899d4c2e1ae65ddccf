import { fetch } from '../../lib/fetch';
export default function (config) {
    function dispatch(url, body) {
        return fetch(url, {
            keepalive: config === null || config === void 0 ? void 0 : config.keepalive,
            headers: { 'Content-Type': 'application/json' },
            method: 'post',
            body: JSON.stringify(body),
        });
    }
    return {
        dispatch: dispatch,
    };
}
//# sourceMappingURL=fetch-dispatcher.js.map