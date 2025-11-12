import type { CST, Document } from "yaml";
import { Composer } from "yaml";
import type { Context } from "./context";
export type ParsedCSTDocs = {
    cstNodes: CST.Token[];
    nodes: Document.Parsed[];
    streamInfo: ReturnType<Composer["streamInfo"]>;
};
/** Parse yaml to CST */
export declare function parseAllDocsToCST(ctx: Context): ParsedCSTDocs;
