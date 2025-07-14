const serializedFields = ['id', 'label', 'prompts', 'icon', 'searchText'];
export const resolvedCommands = (ctx) => {
    const imports = [];
    const commands = [];
    for (const command of ctx.registeredCommands) {
        const fields = getCommandFields(command, imports);
        commands.push(`{ ${fields.join(', ')} }`);
    }
    return `${imports.join('\n')}
export const registeredCommands = [${commands.join(', ')}]
`;
};
function getCommandFields(command, imports) {
    const fields = [];
    for (const field of serializedFields) {
        if (command[field] != null) {
            fields.push(`${field}: ${JSON.stringify(command[field])}`);
        }
    }
    // Add client-side data
    if (command.clientSetupFile) {
        const importedVar = `__setup${imports.length}__`;
        if (typeof command.clientSetupFile === 'string') {
            imports.push(`import ${importedVar} from '${command.clientSetupFile}'`);
        }
        else {
            imports.push(`import { ${command.clientSetupFile.importName} as ${importedVar} } from '${command.clientSetupFile.file}'`);
        }
        fields.push(`...${importedVar}`);
    }
    return fields;
}
