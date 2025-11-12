/** Represents a UUID as a 16-byte byte array. */
export declare class UUID {
    readonly bytes: Readonly<Uint8Array>;
    /** @param bytes - The 16-byte byte array representation. */
    private constructor();
    /**
     * Creates an object from the internal representation, a 16-byte byte array
     * containing the binary UUID representation in the big-endian byte order.
     *
     * This method does NOT shallow-copy the argument, and thus the created object
     * holds the reference to the underlying buffer.
     *
     * @throws TypeError if the length of the argument is not 16.
     */
    static ofInner(bytes: Readonly<Uint8Array>): UUID;
    /**
     * Builds a byte array from UUIDv7 field values.
     *
     * @param unixTsMs - A 48-bit `unix_ts_ms` field value.
     * @param randA - A 12-bit `rand_a` field value.
     * @param randBHi - The higher 30 bits of 62-bit `rand_b` field value.
     * @param randBLo - The lower 32 bits of 62-bit `rand_b` field value.
     * @throws RangeError if any field value is out of the specified range.
     */
    static fromFieldsV7(unixTsMs: number, randA: number, randBHi: number, randBLo: number): UUID;
    /**
     * Builds a byte array from a string representation.
     *
     * This method accepts the following formats:
     *
     * - 32-digit hexadecimal format without hyphens: `0189dcd553117d408db09496a2eef37b`
     * - 8-4-4-4-12 hyphenated format: `0189dcd5-5311-7d40-8db0-9496a2eef37b`
     * - Hyphenated format with surrounding braces: `{0189dcd5-5311-7d40-8db0-9496a2eef37b}`
     * - RFC 4122 URN format: `urn:uuid:0189dcd5-5311-7d40-8db0-9496a2eef37b`
     *
     * Leading and trailing whitespaces represents an error.
     *
     * @throws SyntaxError if the argument could not parse as a valid UUID string.
     */
    static parse(uuid: string): UUID;
    /**
     * @returns The 8-4-4-4-12 canonical hexadecimal string representation
     * (`0189dcd5-5311-7d40-8db0-9496a2eef37b`).
     */
    toString(): string;
    /**
     * @returns The 32-digit hexadecimal representation without hyphens
     * (`0189dcd553117d408db09496a2eef37b`).
     */
    toHex(): string;
    /** @returns The 8-4-4-4-12 canonical hexadecimal string representation. */
    toJSON(): string;
    /**
     * Reports the variant field value of the UUID or, if appropriate, "NIL" or
     * "MAX".
     *
     * For convenience, this method reports "NIL" or "MAX" if `this` represents
     * the Nil or Max UUID, although the Nil and Max UUIDs are technically
     * subsumed under the variants `0b0` and `0b111`, respectively.
     */
    getVariant(): "VAR_0" | "VAR_10" | "VAR_110" | "VAR_RESERVED" | "NIL" | "MAX";
    /**
     * Returns the version field value of the UUID or `undefined` if the UUID does
     * not have the variant field value of `0b10`.
     */
    getVersion(): number | undefined;
    /** Creates an object from `this`. */
    clone(): UUID;
    /** Returns true if `this` is equivalent to `other`. */
    equals(other: UUID): boolean;
    /**
     * Returns a negative integer, zero, or positive integer if `this` is less
     * than, equal to, or greater than `other`, respectively.
     */
    compareTo(other: UUID): number;
}
/**
 * Encapsulates the monotonic counter state.
 *
 * This class provides APIs to utilize a separate counter state from that of the
 * global generator used by {@link uuidv7} and {@link uuidv7obj}. In addition to
 * the default {@link generate} method, this class has {@link generateOrAbort}
 * that is useful to absolutely guarantee the monotonically increasing order of
 * generated UUIDs. See their respective documentation for details.
 */
export declare class V7Generator {
    private timestamp;
    private counter;
    /** The random number generator used by the generator. */
    private readonly random;
    /**
     * Creates a generator object with the default random number generator, or
     * with the specified one if passed as an argument. The specified random
     * number generator should be cryptographically strong and securely seeded.
     */
    constructor(randomNumberGenerator?: {
        /** Returns a 32-bit random unsigned integer. */
        nextUint32(): number;
    });
    /**
     * Generates a new UUIDv7 object from the current timestamp, or resets the
     * generator upon significant timestamp rollback.
     *
     * This method returns a monotonically increasing UUID by reusing the previous
     * timestamp even if the up-to-date timestamp is smaller than the immediately
     * preceding UUID's. However, when such a clock rollback is considered
     * significant (i.e., by more than ten seconds), this method resets the
     * generator and returns a new UUID based on the given timestamp, breaking the
     * increasing order of UUIDs.
     *
     * See {@link generateOrAbort} for the other mode of generation and
     * {@link generateOrResetCore} for the low-level primitive.
     */
    generate(): UUID;
    /**
     * Generates a new UUIDv7 object from the current timestamp, or returns
     * `undefined` upon significant timestamp rollback.
     *
     * This method returns a monotonically increasing UUID by reusing the previous
     * timestamp even if the up-to-date timestamp is smaller than the immediately
     * preceding UUID's. However, when such a clock rollback is considered
     * significant (i.e., by more than ten seconds), this method aborts and
     * returns `undefined` immediately.
     *
     * See {@link generate} for the other mode of generation and
     * {@link generateOrAbortCore} for the low-level primitive.
     */
    generateOrAbort(): UUID | undefined;
    /**
     * Generates a new UUIDv7 object from the `unixTsMs` passed, or resets the
     * generator upon significant timestamp rollback.
     *
     * This method is equivalent to {@link generate} except that it takes a custom
     * timestamp and clock rollback allowance.
     *
     * @param rollbackAllowance - The amount of `unixTsMs` rollback that is
     * considered significant. A suggested value is `10_000` (milliseconds).
     * @throws RangeError if `unixTsMs` is not a 48-bit positive integer.
     */
    generateOrResetCore(unixTsMs: number, rollbackAllowance: number): UUID;
    /**
     * Generates a new UUIDv7 object from the `unixTsMs` passed, or returns
     * `undefined` upon significant timestamp rollback.
     *
     * This method is equivalent to {@link generateOrAbort} except that it takes a
     * custom timestamp and clock rollback allowance.
     *
     * @param rollbackAllowance - The amount of `unixTsMs` rollback that is
     * considered significant. A suggested value is `10_000` (milliseconds).
     * @throws RangeError if `unixTsMs` is not a 48-bit positive integer.
     */
    generateOrAbortCore(unixTsMs: number, rollbackAllowance: number): UUID | undefined;
    /** Initializes the counter at a 42-bit random integer. */
    private resetCounter;
    /**
     * Generates a new UUIDv4 object utilizing the random number generator inside.
     *
     * @internal
     */
    generateV4(): UUID;
}
/**
 * Generates a UUIDv7 string.
 *
 * @returns The 8-4-4-4-12 canonical hexadecimal string representation
 * ("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
 */
export declare const uuidv7: () => string;
/** Generates a UUIDv7 object. */
export declare const uuidv7obj: () => UUID;
/**
 * Generates a UUIDv4 string.
 *
 * @returns The 8-4-4-4-12 canonical hexadecimal string representation
 * ("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
 */
export declare const uuidv4: () => string;
/** Generates a UUIDv4 object. */
export declare const uuidv4obj: () => UUID;
//# sourceMappingURL=uuidv7.d.ts.map