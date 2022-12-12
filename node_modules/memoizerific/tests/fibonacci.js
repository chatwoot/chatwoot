var Memoizerific = require('../src/memoizerific');

describe("fibonacci", () => {
	var fibonacci,
		fibonacciMemoized,
		fibonacciResult,
		fibonacciMemoizedResult,
		fibonacciTime,
		fibonacciMemoizedTime,
		ratioDifference;

	fibonacci = function (n) {
		if (n < 2){
			return 1;
		}
		else {
			return fibonacci(n-2) + fibonacci(n-1);
		}
	};

	fibonacciMemoized = Memoizerific(50)(function (n) {
		if (n < 2){
			return 1;
		}
		else {
			return fibonacciMemoized(n-2) + fibonacciMemoized(n-1);
		}
	});

	fibonacciTime = process.hrtime();
	fibonacciResult = fibonacci(40);
	fibonacciTime = process.hrtime(fibonacciTime);

	fibonacciMemoizedTime = process.hrtime();
	fibonacciMemoizedResult = fibonacciMemoized(40);
	fibonacciMemoizedTime = process.hrtime(fibonacciMemoizedTime);

	ratioDifference = ((fibonacciTime[0] * 1000000000) + fibonacciTime[1]) / ((fibonacciMemoizedTime[0] * 1000000000) + fibonacciMemoizedTime[1]);

	it("should be map or similar", () => { expect(fibonacciMemoized.cache instanceof Map).toEqual(process.env.FORCE_SIMILAR_INSTEAD_OF_MAP !== 'true'); });
	it("should equal non-memoized result", () => { expect(fibonacciResult).toEqual(fibonacciMemoizedResult); });
	it("should have proper lru length", () => { expect(fibonacciMemoized.lru.length).toEqual(41); });
	it("should be at least 10x faster", () => { expect(ratioDifference).toBeGreaterThan(10); });
});