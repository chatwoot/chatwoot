/// <reference types="node" />
import { parseString, ParseStringResult } from './lib/ini';
export { parseString };
export interface KnownProps {
    end_of_line?: 'lf' | 'crlf' | 'unset';
    indent_style?: 'tab' | 'space' | 'unset';
    indent_size?: number | 'tab' | 'unset';
    insert_final_newline?: true | false | 'unset';
    tab_width?: number | 'unset';
    trim_trailing_whitespace?: true | false | 'unset';
    charset?: string | 'unset';
}
export interface ECFile {
    name: string;
    contents: string | Buffer;
}
export interface FileConfig {
    name: string;
    contents: ParseStringResult;
}
export interface ParseOptions {
    config?: string;
    version?: string;
    root?: string;
}
export declare function parseFromFiles(filepath: string, files: Promise<ECFile[]>, options?: ParseOptions): Promise<KnownProps>;
export declare function parseFromFilesSync(filepath: string, files: ECFile[], options?: ParseOptions): KnownProps;
export declare function parse(_filepath: string, _options?: ParseOptions): Promise<KnownProps>;
export declare function parseSync(_filepath: string, _options?: ParseOptions): KnownProps;
