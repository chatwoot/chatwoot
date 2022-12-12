import webpack from 'webpack';
import { ForkTsCheckerWebpackPluginConfiguration } from '../ForkTsCheckerWebpackPluginConfiguration';
import { ForkTsCheckerWebpackPluginState } from '../ForkTsCheckerWebpackPluginState';
import { ReporterRpcClient } from '../reporter';
declare function tapStartToConnectAndRunReporter(compiler: webpack.Compiler, reporter: ReporterRpcClient, configuration: ForkTsCheckerWebpackPluginConfiguration, state: ForkTsCheckerWebpackPluginState): void;
export { tapStartToConnectAndRunReporter };
