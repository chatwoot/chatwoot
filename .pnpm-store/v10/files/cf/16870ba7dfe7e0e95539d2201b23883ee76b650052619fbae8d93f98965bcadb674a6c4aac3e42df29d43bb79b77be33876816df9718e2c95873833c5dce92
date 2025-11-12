/**
 * uuidv7: An experimental implementation of the proposed UUID Version 7
 *
 * @license Apache-2.0
 * @copyright 2021-2023 LiosK
 * @packageDocumentation
 *
 * from https://github.com/LiosK/uuidv7/blob/e501462ea3d23241de13192ceae726956f9b3b7d/src/index.ts
 */
/** Represents a UUID as a 16-byte byte array. */
export declare class UUID {
    readonly bytes: Readonly<Uint8Array>;
    /** @param bytes - The 16-byte byte array representation. */
    constructor(bytes: Readonly<Uint8Array>);
    /**
     * Builds a byte array from UUIDv7 field values.
     *
     * @param unixTsMs - A 48-bit `unix_ts_ms` field value.
     * @param randA - A 12-bit `rand_a` field value.
     * @param randBHi - The higher 30 bits of 62-bit `rand_b` field value.
     * @param randBLo - The lower 32 bits of 62-bit `rand_b` field value.
     */
    static fromFieldsV7(unixTsMs: number, randA: number, randBHi: number, randBLo: number): UUID;
    /** @returns The 8-4-4-4-12 canonical hexadecimal string representation. */
    toString(): string;
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
 * Generates a UUIDv7 string.
 *
 * @returns The 8-4-4-4-12 canonical hexadecimal string representation
 * ("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
 */
export declare const uuidv7: () => string;
export declare const uuid7ToTimestampMs: (uuid: string) => number;
