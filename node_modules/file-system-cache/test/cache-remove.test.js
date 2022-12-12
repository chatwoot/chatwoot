"use strict"
import { expect } from "chai";
import fs from "fs-extra";
import fsPath from "path";
import FileSystemCache from "../src/cache";
import * as f from "../src/funcs";

const BASE_PATH = "./test/samples/get";


describe("remove", function() {
  let cache;
  beforeEach((done) => {
    cache = new FileSystemCache({ basePath: BASE_PATH });
    cache.set("foo", "my-text").then(() => done());
  });

  it("removes the file from the file-system", (done) => {
    expect(f.isFileSync(cache.path("foo"))).to.equal(true);
    cache.remove("foo")
    .then(() => {
        expect(f.isFileSync(cache.path("foo"))).to.equal(false);
        done();
    })
    .catch(err => console.error(err));
  });

  it("does nothing if the key does not exist", (done) => {
    cache.remove("foobar")
    .then(() => done())
    .catch(err => { throw err });
  });
});
