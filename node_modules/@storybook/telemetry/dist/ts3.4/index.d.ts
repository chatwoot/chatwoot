import { EventType, Payload, Options } from './types';
export * from './storybook-metadata';
export declare const telemetry: (eventType: EventType, payload?: Payload, options?: Partial<Options>) => Promise<void>;
