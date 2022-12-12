"use strict"
import { expect } from "chai";
import fs from "fs-extra";
import fsPath from "path";
import FileSystemCache from "../src/cache";
import * as f from "../src/funcs";

const BASE_PATH = "./test/samples/get";
const ABSOLUTE_BASE_PATH = fsPath.resolve(BASE_PATH);


describe("get", function() {
  it("file not exist on the file-system", (done) => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    cache.get("foo")
    .then(result => {
        expect(result).to.equal(undefined);
        done();
    })
    .catch(err => console.error(err));
  });

  it("gets a default value", () => {
    const cache = new FileSystemCache({ basePath: BASE_PATH });
    return cache.get("foo", { myDefault: 123 })
      .then(result => {
        expect(result).to.eql({ myDefault: 123 });
      })
  });

  it("reads a stored values (various types)", (done) => {
    const cache1 = new FileSystemCache({ basePath: BASE_PATH });
    const cache2 = new FileSystemCache({ basePath: BASE_PATH });
    cache1.set("text", "my value");
    cache1.set("number", 123);
    cache1.set("object", { foo: 456 })
    .then(() => {
      cache2.get("text")
      .then(result => expect(result).to.equal("my value"))
      .then(() => {
        cache2.get("number").then(result => expect(result).to.equal(123))
      })
      .then(() => {
        cache2.get("object").then(result => expect(result).to.eql({ foo: 456 }))
      })
      .finally(() => done())
      .catch(err => console.error(err));
    })
  });


  it("reads a stored date", (done) => {
    const cache1 = new FileSystemCache({ basePath: BASE_PATH });
    const cache2 = new FileSystemCache({ basePath: BASE_PATH });
    const now = new Date();
    cache1.set("date", now)
    .then(() => {
      cache2.get("date")
      .then(result => {
          expect(result).to.eql(now);
          done();
      })
      .catch(err => console.error(err));
    })
  });

  describe("getSync", function() {
    it("reads a value synchonously", (done) => {
      const cache = new FileSystemCache({ basePath: BASE_PATH });
      const now = new Date();
      cache.set("date", now)
      .then(() => {
          const result = cache.getSync("date");
          expect(cache.getSync("date")).to.eql(now);
          done();
      })
      .catch(err => console.error(err));
    });

    it("returns a default value synchonously", () => {
      const cache = new FileSystemCache({ basePath: BASE_PATH });
      const result = cache.getSync("my-sync-value", { myDefault: 123 });
      expect(result).to.eql({ myDefault: 123 });
    });
  });
});
