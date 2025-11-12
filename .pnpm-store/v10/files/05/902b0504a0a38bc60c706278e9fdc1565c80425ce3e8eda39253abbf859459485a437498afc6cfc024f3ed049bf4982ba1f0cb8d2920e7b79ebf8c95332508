import { globby } from 'globby';
export async function listComponentFiles(search = '', ignore = [], limit = 10) {
    let files = await globby('**/*.vue', {
        gitignore: true,
        ignore: [
            'node_modules',
            ...ignore,
        ],
    });
    if (search) {
        const searchText = search.toLowerCase();
        files = files.filter(file => file.toLowerCase().includes(searchText));
    }
    return files.slice(0, limit);
}
