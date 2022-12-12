var Memoizerific = require('../src/memoizerific');

describe("wasMemoized", () => {
	var memoizedFn;

	beforeEach(function() {
		memoizedFn = Memoizerific(50)(function(arg1, arg2, arg3) {
			return arg1.num * arg2.num;
		});
	});

	it("should be false before any invocations", () => {
		expect(memoizedFn.wasMemoized).toEqual(false);
	});

	it("should be false after one invocation", () => {
		memoizedFn(1, 2, 3);
		expect(memoizedFn.wasMemoized).toEqual(false);
	});

	it("should be true", () => {
		memoizedFn(1, 2, 3);
		memoizedFn(1, 2, 3);
		expect(memoizedFn.wasMemoized).toEqual(true);
	});

	it("should be false", () => {
		memoizedFn(1, 2, 3);
		memoizedFn(1, 2, 3);
		memoizedFn(4, 5, 6);
		expect(memoizedFn.wasMemoized).toEqual(false);
	});
});

describe("limit", () => {
	var memoizedFn;

	beforeEach(function() {
		memoizedFn = Memoizerific(43)(function(arg1, arg2, arg3) {
			return arg1.num * arg2.num;
		});
	});

	it("should be correct after no invocations", () => {
		expect(memoizedFn.limit).toEqual(43);
	});

	it("should be correct after one invocation", () => {
		memoizedFn(1, 2, 3);
		expect(memoizedFn.limit).toEqual(43);
	});

	it("should be correct after multiple invocations", () => {
		memoizedFn(1, 2, 3);
		memoizedFn(4, 5, 6);
		expect(memoizedFn.limit).toEqual(43);
	});
});