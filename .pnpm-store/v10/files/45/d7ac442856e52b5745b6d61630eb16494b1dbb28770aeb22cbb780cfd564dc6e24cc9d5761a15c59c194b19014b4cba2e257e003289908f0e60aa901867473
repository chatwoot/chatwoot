import RageClick from './extensions/rageclick';
import { Properties, RemoteConfig } from './types';
import { PostHog } from './posthog-core';
export declare function getAugmentPropertiesFromElement(elem: Element): Properties;
export declare function previousElementSibling(el: Element): Element | null;
export declare function getDefaultProperties(eventType: string): Properties;
export declare function getPropertiesFromElement(elem: Element, maskAllAttributes: boolean, maskText: boolean, elementAttributeIgnorelist: string[] | undefined): Properties;
export declare function autocapturePropertiesForElement(target: Element, { e, maskAllElementAttributes, maskAllText, elementAttributeIgnoreList, elementsChainAsString, }: {
    e: Event;
    maskAllElementAttributes: boolean;
    maskAllText: boolean;
    elementAttributeIgnoreList?: string[] | undefined;
    elementsChainAsString: boolean;
}): {
    props: Properties;
    explicitNoCapture?: boolean;
};
export declare class Autocapture {
    instance: PostHog;
    _initialized: boolean;
    _isDisabledServerSide: boolean | null;
    _elementSelectors: Set<string> | null;
    rageclicks: RageClick;
    _elementsChainAsString: boolean;
    constructor(instance: PostHog);
    private get _config();
    _addDomEventHandlers(): void;
    startIfEnabled(): void;
    onRemoteConfig(response: RemoteConfig): void;
    setElementSelectors(selectors: Set<string>): void;
    getElementSelectors(element: Element | null): string[] | null;
    get isEnabled(): boolean;
    private _captureEvent;
    isBrowserSupported(): boolean;
}
