import * as webpack from 'webpack';
import { LoaderOptions } from './interfaces';
/**
 * The entry point for ts-loader
 */
declare function loader(this: webpack.loader.LoaderContext, contents: string): void;
export = loader;
/**
 * expose public types via declaration merging
 */
declare namespace loader {
    interface Options extends LoaderOptions {
    }
}
//# sourceMappingURL=index.d.ts.map