import { Envelope } from '@sentry/types';
/**
 * Creates an envelope.
 * Make sure to always explicitly provide the generic to this function
 * so that the envelope types resolve correctly.
 */
export declare function createEnvelope<E extends Envelope>(headers: E[0], items?: E[1]): E;
/**
 * Add an item to an envelope.
 * Make sure to always explicitly provide the generic to this function
 * so that the envelope types resolve correctly.
 */
export declare function addItemToEnvelope<E extends Envelope>(envelope: E, newItem: E[1][number]): E;
/**
 * Get the type of the envelope. Grabs the type from the first envelope item.
 */
export declare function getEnvelopeType<E extends Envelope>(envelope: E): string;
/**
 * Serializes an envelope into a string.
 */
export declare function serializeEnvelope(envelope: Envelope): string;
//# sourceMappingURL=envelope.d.ts.map