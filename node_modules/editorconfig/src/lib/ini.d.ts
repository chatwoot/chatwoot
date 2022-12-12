/// <reference types="node" />
import { URL } from 'url';
/**
 * Parses an .ini file
 * @param file The location of the .ini file
 */
export declare function parse(file: string | number | Buffer | URL): Promise<[string | null, SectionBody][]>;
export declare function parseSync(file: string | number | Buffer | URL): [string | null, SectionBody][];
export declare type SectionName = string | null;
export interface SectionBody {
    [key: string]: string;
}
export declare type ParseStringResult = Array<[SectionName, SectionBody]>;
export declare function parseString(data: string): ParseStringResult;
