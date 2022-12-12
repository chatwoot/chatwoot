export * from './exports';
import { Integrations as CoreIntegrations } from '@sentry/core';
import * as BrowserIntegrations from './integrations';
import * as Transports from './transports';
declare const INTEGRATIONS: {
    GlobalHandlers: typeof BrowserIntegrations.GlobalHandlers;
    TryCatch: typeof BrowserIntegrations.TryCatch;
    Breadcrumbs: typeof BrowserIntegrations.Breadcrumbs;
    LinkedErrors: typeof BrowserIntegrations.LinkedErrors;
    UserAgent: typeof BrowserIntegrations.UserAgent;
    Dedupe: typeof BrowserIntegrations.Dedupe;
    FunctionToString: typeof CoreIntegrations.FunctionToString;
    InboundFilters: typeof CoreIntegrations.InboundFilters;
};
export { INTEGRATIONS as Integrations, Transports };
//# sourceMappingURL=index.d.ts.map