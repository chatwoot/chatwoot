export function unique(array) {
    return [...new Set(array)];
}
export function groupBy(array, toKey) {
    const map = new Map();
    for (const item of array) {
        const key = toKey(item);
        const oldValue = map.get(key);
        const newValue = oldValue ? [...oldValue, item] : [item];
        map.set(key, newValue);
    }
    return map;
}
//# sourceMappingURL=array.js.map