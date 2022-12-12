import webpack from 'webpack';
import { ForkTsCheckerWebpackPluginState } from '../ForkTsCheckerWebpackPluginState';
import { ReporterRpcClient } from '../reporter';
declare function tapStopToDisconnectReporter(compiler: webpack.Compiler, reporter: ReporterRpcClient, state: ForkTsCheckerWebpackPluginState): void;
export { tapStopToDisconnectReporter };
