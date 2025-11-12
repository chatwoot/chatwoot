function includes(str, needle) {
    return -1 !== str.indexOf(needle);
}
const trim = function(str) {
    return str.trim();
};
const stripLeadingDollar = function(s) {
    return s.replace(/^\$/, '');
};
function isDistinctIdStringLike(value) {
    return [
        'distinct_id',
        'distinctid'
    ].includes(value.toLowerCase());
}
export { includes, isDistinctIdStringLike, stripLeadingDollar, trim };
