var Similar = require('../src/similar');

describe("Foreach with one entry", () => {
	var similar = new Similar(),
		entry = { key: 'stringkey', val: 'stringval' };

	similar.list.push(entry);
	similar.size = 1;

	it("iterates keys", () => {
		similar.forEach((val, key) => {
			expect(key).toEqual(entry.key);
		});
	});

	it("iterates vals", () => {
		similar.forEach((val, key) => {
			expect(val).toEqual(entry.val);
		});
	});
});

describe("Foreach with NaN entries", () => {
	var similar = new Similar(),
		entries = [
			{ key: NaN, val: 'stringval' },
			{ key: undefined, val: { b: 2 } },
			{ key: NaN, val: null },
			{ key: [NaN, 6, '%', { l: 'x'}], val: ['_', 4, { a: 1 }] }
		],
		i = 0;

	entries.forEach(entry => similar.list.push(entry));
	similar.size = entries.length;

	it("iterates keys", () => {
		i = 0;
		similar.forEach((val, key) => {
			expect(key).toEqual(entries[i].key);
			i++;
		});
	});

	it("iterates vals", () => {
		i = 0;
		similar.forEach((val, key) => {
			expect(val).toEqual(entries[i].val);
			i++;
		});
	});
});

describe("Foreach with multiple complex entries", () => {
	var similar = new Similar(),
		entries = [
			{ key: 'stringkey', val: 'stringval' },
			{ key: { a: 1 }, val: { b: 2 } },
			{ key: undefined, val: null },
			{ key: ['a', 6, '%', { l: 'x'}], val: ['_', 4, { a: 1 }] }
		],
		i = 0;

	entries.forEach(entry => similar.list.push(entry));
	similar.size = entries.length;

	it("iterates keys", () => {
		i = 0;
		similar.forEach((val, key) => {
			expect(key).toEqual(entries[i].key);
			i++;
		});
	});

	it("iterates vals", () => {
		i = 0;
		similar.forEach((val, key) => {
			expect(val).toEqual(entries[i].val);
			i++;
		});
	});
});