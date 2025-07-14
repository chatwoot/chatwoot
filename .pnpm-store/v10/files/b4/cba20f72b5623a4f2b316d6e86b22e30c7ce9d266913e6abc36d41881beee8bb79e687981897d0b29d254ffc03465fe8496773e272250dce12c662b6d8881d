import { c as AgentCommands, A as Agent, C as Command, R as ResolvedCommand, b as AgentCommandValue } from './shared/package-manager-detector.63008cb6.mjs';

declare const COMMANDS: {
    npm: AgentCommands;
    yarn: AgentCommands;
    'yarn@berry': AgentCommands;
    pnpm: AgentCommands;
    'pnpm@6': AgentCommands;
    bun: AgentCommands;
};
declare function resolveCommand(agent: Agent, command: Command, args: string[]): ResolvedCommand | null;
declare function constructCommand(value: AgentCommandValue, args: string[]): ResolvedCommand | null;

export { COMMANDS, constructCommand, resolveCommand };
