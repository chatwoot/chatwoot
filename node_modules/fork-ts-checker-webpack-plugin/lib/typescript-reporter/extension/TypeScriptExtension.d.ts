import * as ts from 'typescript';
import { Issue } from '../../issue';
import { Dependencies } from '../../reporter';
interface TypeScriptHostExtension {
    extendWatchSolutionBuilderHost?<TProgram extends ts.BuilderProgram, THost extends ts.SolutionBuilderWithWatchHost<TProgram>>(host: THost, parsedCommandLine?: ts.ParsedCommandLine): THost;
    extendWatchCompilerHost?<TProgram extends ts.BuilderProgram, THost extends ts.WatchCompilerHost<TProgram>>(host: THost, parsedCommandLine?: ts.ParsedCommandLine): THost;
    extendCompilerHost?<THost extends ts.CompilerHost>(host: THost, parsedCommandLine?: ts.ParsedCommandLine): THost;
    extendParseConfigFileHost?<THost extends ts.ParseConfigFileHost>(host: THost): THost;
}
interface TypeScriptReporterExtension {
    extendIssues?(issues: Issue[]): Issue[];
    extendDependencies?(dependencies: Dependencies): Dependencies;
}
interface TypeScriptExtension extends TypeScriptHostExtension, TypeScriptReporterExtension {
}
export { TypeScriptExtension, TypeScriptReporterExtension, TypeScriptHostExtension };
