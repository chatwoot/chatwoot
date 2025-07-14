export * from './interfaces';
import { ID, User } from '../user';
import { Integrations, EventProperties, CoreSegmentEvent, CoreOptions, UserTraits, GroupTraits } from './interfaces';
interface EventFactorySettings {
    createMessageId: () => string;
    user?: User;
}
export declare class EventFactory {
    createMessageId: EventFactorySettings['createMessageId'];
    user?: User;
    constructor(settings: EventFactorySettings);
    track(event: string, properties?: EventProperties, options?: CoreOptions, globalIntegrations?: Integrations): CoreSegmentEvent;
    page(category: string | null, page: string | null, properties?: EventProperties, options?: CoreOptions, globalIntegrations?: Integrations): CoreSegmentEvent;
    screen(category: string | null, screen: string | null, properties?: EventProperties, options?: CoreOptions, globalIntegrations?: Integrations): CoreSegmentEvent;
    identify(userId: ID, traits?: UserTraits, options?: CoreOptions, globalIntegrations?: Integrations): CoreSegmentEvent;
    group(groupId: ID, traits?: GroupTraits, options?: CoreOptions, globalIntegrations?: Integrations): CoreSegmentEvent;
    alias(to: string, from: string | null, // TODO: can we make this undefined?
    options?: CoreOptions, globalIntegrations?: Integrations): CoreSegmentEvent;
    private baseEvent;
    /**
     * Builds the context part of an event based on "foreign" keys that
     * are provided in the `Options` parameter for an Event
     */
    private context;
    normalize(event: CoreSegmentEvent): CoreSegmentEvent;
}
//# sourceMappingURL=index.d.ts.map