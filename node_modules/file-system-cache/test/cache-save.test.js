"use strict"
import { expect } from "chai";
import fs from "fs-extra";
import fsPath from "path";
import FileSystemCache from "../src/cache";
import * as f from "../src/funcs";

const BASE_PATH = "./test/samples/save";



describe("save", function() {
  it("throws if items not valid", () => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    expect(() => cache.save([1])).to.throw();
    expect(() => cache.save([{}])).to.throw();
    expect(() => cache.save([{ key:1 }])).to.throw();
    expect(() => cache.save([{ value:"foo" }])).to.throw();
  });

  it("resolves immediately if an empty array was passed", (done) => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    cache.save([])
    .then(result => {
        expect(result.paths.length).to.equal(0);
        done();
    })
    .catch(err => console.error(err));
  });


  it("saves several files", (done) => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    const payload = [
      { key: "one", value: "value-1" },
      null, // Should not break with null values.
      { key: "two", value: { foo: "value-2" }}
    ];
    cache.save(payload)
    .then(result => {
        const paths = result.paths;
        expect(paths.length).to.equal(2);
        expect(fs.existsSync(paths[0])).to.equal(true);
        expect(fs.existsSync(paths[1])).to.equal(true);
        expect(cache.getSync("one")).to.equal("value-1");
        expect(cache.getSync("two").foo).to.equal("value-2");
        done();
    })
    .catch(err => console.error(err));
  });
});
