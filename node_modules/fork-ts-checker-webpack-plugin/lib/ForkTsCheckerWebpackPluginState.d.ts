import { Tap } from 'tapable';
import { Dependencies, Report } from './reporter';
import { Issue } from './issue';
interface ForkTsCheckerWebpackPluginState {
    reportPromise: Promise<Report | undefined>;
    issuesPromise: Promise<Issue[] | undefined>;
    dependenciesPromise: Promise<Dependencies | undefined>;
    lastDependencies: Dependencies | undefined;
    watching: boolean;
    initialized: boolean;
    webpackDevServerDoneTap: Tap | undefined;
}
declare function createForkTsCheckerWebpackPluginState(): ForkTsCheckerWebpackPluginState;
export { ForkTsCheckerWebpackPluginState, createForkTsCheckerWebpackPluginState };
