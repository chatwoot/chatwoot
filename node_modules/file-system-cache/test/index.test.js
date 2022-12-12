import { expect } from "chai";
import CacheFs from "../src";
import FileSystemCache from "../src/cache";



describe("Module entry API", function() {
  it("creates an instance of [FileSystemCache]", () => {
    const cache = CacheFs();
    expect(cache).to.be.an.instanceof(FileSystemCache);
  });
});
