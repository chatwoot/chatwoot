// @ts-expect-error virtual module
import { collectSupportPlugins } from 'virtual:$histoire-support-plugins-collect';
export async function run(payload) {
    const { run } = await collectSupportPlugins[payload.file.supportPluginId]();
    const result = await run(payload);
    return result;
}
