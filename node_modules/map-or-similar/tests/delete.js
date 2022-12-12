var Similar = require('../src/similar');

describe("simple key", () => {
	var similar = new Similar(),
		entry = { key: 'stringkey', val: 'stringval' };

	similar.set(entry.key, entry.val);
	similar.delete(entry.key);

	it("has proper length", () => { expect(similar.list.length).toEqual(0); });
	it("has proper size", () => { expect(similar.size).toEqual(0); });
	it("has proper lastItem", () => { expect(similar.lastItem).toEqual(undefined); });
	it("resolves has() correctly", () => { expect(similar.has(entry.key)).toEqual(false); expect(similar.has(undefined)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(entry.key)).toEqual(undefined); });
});

describe("NaN key", () => {
	var similar = new Similar(),
		entry1 = { key: NaN, val: { prop: 'propval' } },
		entry2 = { key: ['x','y'], val: { prop: 'propval2' } };

	similar.set(entry1.key, entry1.val);
	similar.set(entry2.key, entry2.val);
	similar.delete(entry1.key);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(entry2.key); });
	it("resolves entry1 has() correctly", () => { expect(similar.has(entry1.key)).toEqual(false);  });
	it("resolves entry1 get() correctly", () => { expect(similar.get(entry1.key)).toEqual(undefined); });
	it("resolves entry2 has() correctly", () => { expect(similar.has(entry2.key)).toEqual(true); });
	it("resolves entry2 get() correctly", () => { expect(similar.get(entry2.key)).toEqual(entry2.val); });

	if (!!Map) {
		var map = new Map();

		map.set(entry1.key, entry1.val);
		map.set(entry2.key, entry2.val);
		map.delete(entry1.key);

		it("matches Map entry1 has() correctly", () => { expect(similar.has(entry1.key)).toEqual(map.has(entry1.key)); });
		it("matches Map entry1 get() correctly", () => { expect(similar.get(entry1.key)).toEqual(map.get(entry1.key)); });
		it("matches Map entry2 has() correctly", () => { expect(similar.has(entry2.key)).toEqual(similar.has(entry2.key)); });
		it("matches Map entry2 get() correctly", () => { expect(similar.get(entry2.key)).toEqual(similar.get(entry2.key)); });
	}
});

describe("complex key", () => {
	var similar = new Similar(),
		entry1 = { key: ['a','b'], val: { prop: 'propval' } },
		entry2 = { key: ['x','y'], val: { prop: 'propval2' } };

	similar.set(entry1.key, entry1.val);
	similar.set(entry2.key, entry2.val);
	similar.delete(entry1.key);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(entry2.key); });
	it("resolves entry1 has() correctly", () => { expect(similar.has(entry1.key)).toEqual(false);  });
	it("resolves entry1 get() correctly", () => { expect(similar.get(entry1.key)).toEqual(undefined); });
	it("resolves entry2 has() correctly", () => { expect(similar.has(entry2.key)).toEqual(true); });
	it("resolves entry2 get() correctly", () => { expect(similar.get(entry2.key)).toEqual(entry2.val); });

	if (!!Map) {
		var map = new Map();

		map.set(entry1.key, entry1.val);
		map.set(entry2.key, entry2.val);
		map.delete(entry1.key);

		it("matches Map entry1 has() correctly", () => { expect(similar.has(entry1.key)).toEqual(map.has(entry1.key)); });
		it("matches Map entry1 get() correctly", () => { expect(similar.get(entry1.key)).toEqual(map.get(entry1.key)); });
		it("matches Map entry2 has() correctly", () => { expect(similar.has(entry2.key)).toEqual(similar.has(entry2.key)); });
		it("matches Map entry2 get() correctly", () => { expect(similar.get(entry2.key)).toEqual(similar.get(entry2.key)); });
	}
});

describe("from empty cache", () => {
	var similar = new Similar(),
		entry = { key: 'stringkey', val: 'stringval' };

	similar.delete(entry.key);

	it("has proper length", () => { expect(similar.list.length).toEqual(0); });
	it("has proper size", () => { expect(similar.size).toEqual(0); });
	it("has proper lastItem", () => { expect(similar.lastItem).toEqual(undefined); });
	it("resolves has() correctly", () => { expect(similar.has(entry.key)).toEqual(false); expect(similar.has(undefined)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(entry.key)).toEqual(undefined); });

	if (!!Map) {
		var map = new Map();

		map.delete(entry.key);

		it("resolves has() correctly", () => { expect(map.has(entry.key)).toEqual(false); expect(map.has(undefined)).toEqual(false); });
		it("resolves get() correctly", () => { expect(map.get(entry.key)).toEqual(undefined); });
	}
});