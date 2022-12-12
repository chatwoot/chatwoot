export interface MdxOptions {
    filepath?: string;
    skipExport?: boolean;
    wrapExport?: string;
    remarkPlugins?: any[];
    rehypePlugins?: any[];
}
interface CompilerOptions {
    filepath?: string;
}
export declare const wrapperJs: string;
export declare function createCompiler(mdxOptions: MdxOptions): (options?: CompilerOptions) => void;
export {};
