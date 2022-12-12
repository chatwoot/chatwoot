import * as webpack from 'webpack';
import { TSInstance } from './interfaces';
/**
 * This returns a function that has options to add assets and also to provide errors to webpack
 * In webpack 4 we can do both during the afterCompile hook
 * In webpack 5 only errors should be provided during aftercompile.  Assets should be
 * emitted during the afterProcessAssets hook
 */
export declare function makeAfterCompile(instance: TSInstance, configFilePath: string | undefined): (compilation: webpack.compilation.Compilation, callback: () => void) => void;
//# sourceMappingURL=after-compile.d.ts.map