import * as ts from 'typescript';
import { TypeScriptConfigurationOverwrite } from '../TypeScriptConfigurationOverwrite';
import { Dependencies } from '../../reporter';
declare function parseTypeScriptConfiguration(typescript: typeof ts, configFileName: string, configFileContext: string, configOverwriteJSON: TypeScriptConfigurationOverwrite, parseConfigFileHost: ts.ParseConfigFileHost): ts.ParsedCommandLine;
declare function getDependenciesFromTypeScriptConfiguration(typescript: typeof ts, parsedConfiguration: ts.ParsedCommandLine, configFileContext: string, parseConfigFileHost: ts.ParseConfigFileHost, processedConfigFiles?: string[]): Dependencies;
export { parseTypeScriptConfiguration, getDependenciesFromTypeScriptConfiguration };
