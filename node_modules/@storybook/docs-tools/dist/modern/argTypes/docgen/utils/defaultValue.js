const BLACKLIST = ['null', 'undefined'];
export function isDefaultValueBlacklisted(value) {
  return BLACKLIST.some(x => x === value);
}