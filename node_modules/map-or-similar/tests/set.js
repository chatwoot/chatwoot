var Similar = require('../src/similar');

describe("simple keys", () => {
	var similar = new Similar(),
		entry = { key: 'stringkey', val: 'stringval' };

	similar.set(entry.key, entry.val);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper key", () => { expect(similar.list[0].key).toEqual(entry.key); });
	it("has proper val", () => { expect(similar.list[0].val).toEqual(entry.val); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(entry.key); expect(similar.lastItem.val).toEqual(entry.val); });
	it("resolves has() correctly", () => { expect(similar.has(entry.key)).toEqual(true); expect(similar.has(entry.val)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(entry.key)).toEqual(entry.val); });

});

describe("NaN keys", () => {
	var similar = new Similar(),
		key = NaN,
		val1 = 'val1',
		val2 = 'val2';

	similar.set(key, val1);
	similar.set(key, val2);
	similar.set(key, val1);
	similar.set(key, val2);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper key", () => { expect(similar.list[0].key).toEqual(key); });
	it("has proper val", () => { expect(similar.list[0].val).toEqual(val2); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(key); expect(similar.lastItem.val).toEqual(val2); });
	it("resolves has() correctly", () => { expect(similar.has(key)).toEqual(true); expect(similar.has(val2)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(key)).toEqual(val2); });

	if (!!Map) {
		var map = new Map();

		map.set(key, val1);
		map.set(key, val2);
		map.set(key, val1);
		map.set(key, val2);

		it("matches Map get()", () => { expect(similar.get(key)).toEqual(map.get(key)); });
		it("matches Map has()", () => { expect(similar.has(key)).toEqual(map.has(key)); });
	}
});

describe("complex keys", () => {
	var similar = new Similar(),
		entry = { key: { prop: ['a', 'b'] }, val: { prop: 'val1' } };

	similar.set(entry.key, entry.val);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper key", () => { expect(similar.list[0].key).toEqual(entry.key); });
	it("has proper val", () => { expect(similar.list[0].val).toEqual(entry.val); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(entry.key); expect(similar.lastItem.val).toEqual(entry.val); });
	it("resolves has() correctly", () => { expect(similar.has(entry.key)).toEqual(true); expect(similar.has(entry.val)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(entry.key)).toEqual(entry.val); });

	if (!!Map) {
		var map = new Map();
		map.set(entry.key, entry.val);
		it("matches Map get()", () => { expect(similar.get(entry.key)).toEqual(map.get(entry.key)); });
		it("matches Map has()", () => { expect(similar.has(entry.key)).toEqual(map.has(entry.key)); });
	}
});

describe("undefined keys and values", () => {
	var similar = new Similar(),
		entry = { key: undefined, val: undefined };

	similar.set(entry.key, entry.val);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper key", () => { expect(similar.list[0].key).toEqual(entry.key); });
	it("has proper val", () => { expect(similar.list[0].val).toEqual(entry.val); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(entry.key); expect(similar.lastItem.val).toEqual(entry.val); });
	it("resolves has() correctly", () => { expect(similar.has(entry.key)).toEqual(true); expect(similar.has(null)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(entry.key)).toEqual(entry.val); });

	if (!!Map) {
		var map = new Map();
		map.set(entry.key, entry.val);
		it("matches Map get()", () => { expect(similar.get(entry.key)).toEqual(map.get(entry.key)); });
		it("matches Map has()", () => { expect(similar.has(entry.key)).toEqual(map.has(entry.key)); });
	}
});

describe("same keys (replace)", () => {
	var similar = new Similar(),
		key = { key: { prop: ['a', 'b'] }},
		val1 = 'val1',
		val2 = 'val2';

	similar.set(key, val1);
	similar.set(key, val2);
	similar.set(key, val1);
	similar.set(key, val2);

	it("has proper length", () => { expect(similar.list.length).toEqual(1); });
	it("has proper size", () => { expect(similar.size).toEqual(1); });
	it("has proper key", () => { expect(similar.list[0].key).toEqual(key); });
	it("has proper val", () => { expect(similar.list[0].val).toEqual(val2); });
	it("has proper lastItem", () => { expect(similar.lastItem.key).toEqual(key); expect(similar.lastItem.val).toEqual(val2); });
	it("resolves has() correctly", () => { expect(similar.has(key)).toEqual(true); expect(similar.has(val2)).toEqual(false); });
	it("resolves get() correctly", () => { expect(similar.get(key)).toEqual(val2); });

	if (!!Map) {
		var map = new Map();

		map.set(key, val1);
		map.set(key, val2);
		map.set(key, val1);
		map.set(key, val2);

		it("matches Map get()", () => { expect(similar.get(key)).toEqual(map.get(key)); });
		it("matches Map has()", () => { expect(similar.has(key)).toEqual(map.has(key)); });
	}
});