import pc from 'picocolors';
export async function wrapLogError(id, cb) {
    try {
        await cb();
    }
    catch (e) {
        console.error(pc.red(`[Error] ${id}: ${e}`));
    }
}
