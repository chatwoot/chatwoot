import * as webpack from 'webpack';
import { TSInstance } from './interfaces';
/**
 * Make function which will manually update changed files
 */
export declare function makeWatchRun(instance: TSInstance, loader: webpack.loader.LoaderContext): (compiler: webpack.Compiler, callback: (err?: Error | undefined) => void) => void;
//# sourceMappingURL=watch-run.d.ts.map