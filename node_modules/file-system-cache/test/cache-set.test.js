"use strict"
import { expect } from "chai";
import fs from "fs-extra";
import fsPath from "path";
import FileSystemCache from "../src/cache";
import * as f from "../src/funcs";

const BASE_PATH = "./test/samples/set";
const ABSOLUTE_BASE_PATH = fsPath.resolve(BASE_PATH);


describe("set", function() {
  it("saves a string to the file-system", (done) => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    const path = cache.path("foo");
    const value = "my value"
    expect(fs.existsSync(path)).to.equal(false);
    cache.set("foo", value)
    .then(result => {
        expect(result.path).to.equal(path);
        expect(f.readFileSync(path)).to.include("my value");
        done();
    })
    .catch(err => console.error(err));
  });

  it("saves an object to the file-system", (done) => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    const value = { text:"hello", number: 123 };
    cache.set("foo", value)
    .then(result => {
        const fileText = f.readFileSync(result.path);
        expect(fileText).to.include("hello");
        expect(fileText).to.include("123");
        done();
    })
    .catch(err => console.error(err));
  });

  it("setSync: saves a value synchonously", () => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    const result = cache.setSync("foo", { text: "sync" });
    expect(result).to.equal(cache);
    expect(cache.getSync("foo")).to.eql({ text: "sync" });
  });
});
