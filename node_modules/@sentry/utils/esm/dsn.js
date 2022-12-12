import { __read } from "tslib";
import { SentryError } from './error';
import { IS_DEBUG_BUILD } from './flags';
/** Regular expression used to parse a Dsn. */
var DSN_REGEX = /^(?:(\w+):)\/\/(?:(\w+)(?::(\w+))?@)([\w.-]+)(?::(\d+))?\/(.+)/;
function isValidProtocol(protocol) {
    return protocol === 'http' || protocol === 'https';
}
/**
 * Renders the string representation of this Dsn.
 *
 * By default, this will render the public representation without the password
 * component. To get the deprecated private representation, set `withPassword`
 * to true.
 *
 * @param withPassword When set to true, the password will be included.
 */
export function dsnToString(dsn, withPassword) {
    if (withPassword === void 0) { withPassword = false; }
    var host = dsn.host, path = dsn.path, pass = dsn.pass, port = dsn.port, projectId = dsn.projectId, protocol = dsn.protocol, publicKey = dsn.publicKey;
    return (protocol + "://" + publicKey + (withPassword && pass ? ":" + pass : '') +
        ("@" + host + (port ? ":" + port : '') + "/" + (path ? path + "/" : path) + projectId));
}
function dsnFromString(str) {
    var match = DSN_REGEX.exec(str);
    if (!match) {
        throw new SentryError("Invalid Sentry Dsn: " + str);
    }
    var _a = __read(match.slice(1), 6), protocol = _a[0], publicKey = _a[1], _b = _a[2], pass = _b === void 0 ? '' : _b, host = _a[3], _c = _a[4], port = _c === void 0 ? '' : _c, lastPath = _a[5];
    var path = '';
    var projectId = lastPath;
    var split = projectId.split('/');
    if (split.length > 1) {
        path = split.slice(0, -1).join('/');
        projectId = split.pop();
    }
    if (projectId) {
        var projectMatch = projectId.match(/^\d+/);
        if (projectMatch) {
            projectId = projectMatch[0];
        }
    }
    return dsnFromComponents({ host: host, pass: pass, path: path, projectId: projectId, port: port, protocol: protocol, publicKey: publicKey });
}
function dsnFromComponents(components) {
    // TODO this is for backwards compatibility, and can be removed in a future version
    if ('user' in components && !('publicKey' in components)) {
        components.publicKey = components.user;
    }
    return {
        user: components.publicKey || '',
        protocol: components.protocol,
        publicKey: components.publicKey || '',
        pass: components.pass || '',
        host: components.host,
        port: components.port || '',
        path: components.path || '',
        projectId: components.projectId,
    };
}
function validateDsn(dsn) {
    if (!IS_DEBUG_BUILD) {
        return;
    }
    var port = dsn.port, projectId = dsn.projectId, protocol = dsn.protocol;
    var requiredComponents = ['protocol', 'publicKey', 'host', 'projectId'];
    requiredComponents.forEach(function (component) {
        if (!dsn[component]) {
            throw new SentryError("Invalid Sentry Dsn: " + component + " missing");
        }
    });
    if (!projectId.match(/^\d+$/)) {
        throw new SentryError("Invalid Sentry Dsn: Invalid projectId " + projectId);
    }
    if (!isValidProtocol(protocol)) {
        throw new SentryError("Invalid Sentry Dsn: Invalid protocol " + protocol);
    }
    if (port && isNaN(parseInt(port, 10))) {
        throw new SentryError("Invalid Sentry Dsn: Invalid port " + port);
    }
    return true;
}
/** The Sentry Dsn, identifying a Sentry instance and project. */
export function makeDsn(from) {
    var components = typeof from === 'string' ? dsnFromString(from) : dsnFromComponents(from);
    validateDsn(components);
    return components;
}
//# sourceMappingURL=dsn.js.map