"use strict"
import { expect } from "chai";
import fs from "fs-extra";
import fsPath from "path";
import FileSystemCache from "../src/cache";
import * as f from "../src/funcs";

const BASE_PATH = "./test/samples/load";

describe("load", function() {
  it("loads no files", (done) => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    cache.load()
    .then(result => {
        expect(result.files.length).to.equal(0);
        done();
    })
    .catch(err => console.error(err));
  });


  it("loads several files (no namespace)", (done) => {
    const cache1 = new FileSystemCache({ basePath: BASE_PATH });
    const cache2 = new FileSystemCache({ basePath: BASE_PATH, ns: "my-ns" });
    cache1.setSync("foo", 1);
    cache1.setSync("bar", "two");
    cache2.set("yo", "ns-value");
    cache1.load()
    .then(result => {
        const files = result.files;
        expect(files.length).to.equal(2);
        expect(files[0].value).to.equal("two");
        expect(files[1].value).to.equal(1);
        done();
    })
    .catch(err => console.error(err));
  });
});
