import path from 'node:path';
import {findUp, findUpSync} from 'find-up';

export async function packageDirectory({cwd} = {}) {
	const filePath = await findUp('package.json', {cwd});
	return filePath && path.dirname(filePath);
}

export function packageDirectorySync({cwd} = {}) {
	const filePath = findUpSync('package.json', {cwd});
	return filePath && path.dirname(filePath);
}
