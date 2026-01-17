import pc from 'picocolors';
export function createPath(config, file) {
    if (config.tree.file === 'title') {
        return file.title.split('/');
    }
    if (config.tree.file === 'path') {
        const paths = file.path.split('/').slice(0, -1);
        // check if tree file path is a plugin
        const index = paths.findIndex(p => p.includes('.histoire'));
        if (index !== -1) {
            return ['plugins', file.title];
        }
        return [...paths, file.title];
    }
    return config.tree.file(file);
}
export function makeTree(config, files) {
    const groups = config.tree?.groups?.map(g => ({
        groupConfig: g,
        treeObject: {},
    })) || [];
    const defaultGroup = {
        treeObject: {},
    };
    groups.push(defaultGroup);
    files.forEach((file, index) => {
        const group = getGroup(file);
        setPath(file.treePath, index, group.treeObject);
    });
    let sortingFunction = (a, b) => a.localeCompare(b);
    if (config.tree.order !== 'asc') {
        sortingFunction = config.tree.order;
    }
    const result = [];
    for (const group of groups) {
        if (group === defaultGroup) {
            result.push(...buildTree(group.treeObject));
        }
        else {
            result.push({
                group: true,
                id: group.groupConfig.id,
                title: group.groupConfig.title,
                children: buildTree(group.treeObject),
            });
        }
    }
    return result;
    function getGroup(file) {
        if (file.story?.group) {
            const group = groups.find(g => g.groupConfig?.id === file.story.group);
            if (group) {
                return group;
            }
            else {
                console.error(pc.red(`Group ${file.story.group} not found for story ${file.path}`));
            }
        }
        for (const group of groups) {
            if (group.groupConfig?.include && group.groupConfig.include(file.treeFile)) {
                return group;
            }
        }
        return defaultGroup;
    }
    function setPath(path, value, tree) {
        path.reduce((subtree, key, i) => {
            if (i === path.length - 1) {
                setKey(subtree, key, value);
            }
            else if (isLeaf(subtree[key])) {
                setKey(subtree, key, subtree[key]);
                subtree[key] = {};
            }
            else if (!subtree[key]) {
                subtree[key] = {};
            }
            return subtree[key];
        }, tree);
        function isLeaf(element) {
            return !isNaN(element);
        }
    }
    function setKey(tree, key, value) {
        if (isUndefined(tree[key])) {
            tree[key] = value;
            return;
        }
        let copyNumber = 1;
        while (!isUndefined(tree[`${key}-${copyNumber}`])) {
            copyNumber++;
        }
        tree[`${key}-${copyNumber}`] = value;
        function isUndefined(element) {
            return element === undefined;
        }
    }
    function buildTree(treeObject) {
        const tree = [];
        for (const [key, element] of Object.entries(treeObject)) {
            if (Number.isInteger(element)) {
                tree.push({
                    title: key,
                    index: element,
                });
            }
            else {
                tree.push({
                    title: key,
                    children: buildTree(element),
                });
            }
        }
        tree.sort((a, b) => sortingFunction(a.title, b.title));
        return tree;
    }
}
