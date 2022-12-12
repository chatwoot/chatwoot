var Memoizerific = require('../src/memoizerific');

describe("different number of args between calls", () => {
	var memoizedFn,
		res,
		arg1 = 1,
		arg2 = 2,
		arg3 = 3,
		arg4 = 4,
		arg5 = 5;

	beforeEach(function() {
		memoizedFn = Memoizerific(50)(function(arg1, arg2, arg3, arg4, arg5) {
			return 'memoized result ' + arguments.length;
		});
		memoizedFn(arg1, arg2, arg3);
	});

	it("right number of args", () => {
		res = memoizedFn(arg1, arg2, arg4);
		expect(res).toEqual('memoized result 3');
		expect(memoizedFn.wasMemoized).toEqual(false);
		expect(memoizedFn.lru.length).toEqual(2);
	});

	it("one more arg", () => {
		expect(function() { memoizedFn(arg1, arg2, arg3, arg4) }).toThrow();
		/*
		res = memoizedFn(arg1, arg2, arg3, arg4);
		expect(res).toEqual('memoized result 4');
		expect(memoizedFn.wasMemoized).toEqual(true);
		expect(memoizedFn.lru.length).toEqual(1);
		*/
	});

	it("several more args", () => {
		expect(function() { memoizedFn(arg1, arg2, arg3, arg4, arg5) }).toThrow();

		/*
		res = memoizedFn(arg1, arg2, arg3, arg4, arg5);
		expect(res).toEqual('memoized result 5');
		expect(memoizedFn.wasMemoized).toEqual(true);
		expect(memoizedFn.lru.length).toEqual(1);
		*/
	});

	it("one fewer args", () => {
		expect(function() { memoizedFn(arg1, arg2) }).toThrow();

		/*
		res = memoizedFn(arg1, arg2);
		expect(res).toEqual('memoized result 2');
		expect(memoizedFn.wasMemoized).toEqual(true);
		expect(memoizedFn.lru.length).toEqual(1);
		*/
	});

	it("several fewer args", () => {
		expect(function() { memoizedFn(arg1) }).toThrow();

		/*
		res = memoizedFn(arg1);
		expect(res).toEqual('memoized result 1');
		expect(memoizedFn.wasMemoized).toEqual(true);
		expect(memoizedFn.lru.length).toEqual(1);
		*/
	});
});
