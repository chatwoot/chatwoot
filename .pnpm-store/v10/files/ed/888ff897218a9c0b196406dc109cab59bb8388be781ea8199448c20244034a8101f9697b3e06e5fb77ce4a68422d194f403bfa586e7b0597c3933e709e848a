type KeyWithWeight = {
    name: string;
    weight: number;
};
type Keys = Array<KeyWithWeight | string>;
/**
 * Searches for objects in an array based on a search term and a set of keys.
 * @param {T[]} objectsArray - The array of objects to search.
 * @param {string} searchTerm - The search term to match against the objects.
 * @param {Keys} keys - The keys to search in each object.
 * @param {PicoSearchConfig} [config] - Configuration options for the search.
 * @returns {T[]} An array of objects that match the search criteria, ordered by their similarity from the search term.
 */
declare function picoSearch<T>(objectsArray: T[], searchTerm: string, keys: Keys, config: {
    threshold: number;
}): T[];

export { picoSearch };
