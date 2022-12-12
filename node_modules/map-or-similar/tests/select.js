var Similar = require('../src/similar');

describe("map may or may not exist", () => {
	var MapOrSimilar = require('../src/map-or-similar'),
		mapOrSimilar = new MapOrSimilar();

	it("chose Map because it exists", () => { expect(mapOrSimilar instanceof Map).toEqual(true); });
});

describe("force similar", () => {
	var MapOrSimilar = require('../src/map-or-similar'),
		mapOrSimilar = new MapOrSimilar(true);

	it("was forced to similar", () => { expect(mapOrSimilar instanceof Similar).toEqual(true); });
});
