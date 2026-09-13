const LINE_WIDTH = 76;

// Display the saved Scheme syntax, not its persistence envelope.
export function formatBinding(value) {
  if (Array.isArray(value)) {
    const parts = value.map(formatBinding);
    const inline = `(${parts.join(' ')})`;
    if (inline.length <= LINE_WIDTH && !inline.includes('\n')) return inline;
    return `(${parts[0]}\n  ${parts.slice(1).join('\n').replaceAll('\n', '\n  ')})`;
  }
  if (value === true) return '#t';
  if (value === false) return '#f';
  if (value === null) return '()';
  if (typeof value !== 'object') return JSON.stringify(value);
  if (value.type === 'symbol') return value.value;
  if (value.type === 'reference') return `#<reference ${value.id}>`;
  if (value.type === 'closure') {
    return formatBinding([
      { type: 'symbol', value: 'lambda' },
      value.parameters,
      ...value.body,
    ]);
  }
  if (value.type === 'hash') {
    return formatBinding([
      { type: 'symbol', value: 'hash' },
      ...value.value.flat(),
    ]);
  }
  return formatBinding(value.values);
}
