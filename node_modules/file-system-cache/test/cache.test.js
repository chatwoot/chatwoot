"use strict"
import { expect } from "chai";
import fs from "fs-extra";
import fsPath from "path";
import FileSystemCache from "../src/cache";
import * as f from "../src/funcs";

const BASE_PATH = "./test/samples/cache";
const ABSOLUTE_BASE_PATH = fsPath.resolve(BASE_PATH);



describe("FileSystemCache", function() {

  describe("basePath", function() {
    it("has a default path of '/.cache'", () => {
      const cache = new FileSystemCache();
      expect(cache.basePath).to.equal(fsPath.resolve("./.cache"));
    });

    it("resolves the path if the path starts with ('.')", () => {
      const path = "./test/foo"
      const cache = new FileSystemCache({ basePath: path });
      expect(cache.basePath).to.equal(fsPath.resolve(path));
    });

    it("uses the given absolute path", () => {
      const path = "/foo"
      const cache = new FileSystemCache({ basePath: path });
      expect(cache.basePath).to.equal(path);
    });

    it("throws if the basePath is a file", () => {
      let fn = () => {
        new FileSystemCache({ basePath: "./README.md" });
      };
      expect(fn).to.throw();
    });
  });


  describe("ns (namespace)", function() {
    it("has no namespace by default", () => {
      expect(new FileSystemCache().ns).to.equal(undefined);
      expect(new FileSystemCache([]).ns).to.equal(undefined);
      expect(new FileSystemCache([null, undefined]).ns).to.equal(undefined);
    });

    it("creates a namespace hash with a single value", () => {
      const cache = new FileSystemCache({ ns:"foo" });
      expect(cache.ns).to.equal(f.hash("foo"));
    });

    it("creates a namespace hash with several values", () => {
      const cache = new FileSystemCache({ ns:["foo", 123] });
      expect(cache.ns).to.equal(f.hash("foo", 123));
    });
  });


  describe("path", function() {
    it("throws if no key is provided", () => {
      const cache = new FileSystemCache({ basePath: BASE_PATH });
      expect(() => cache.path()).to.throw();
    });

    it("returns a path with no namespace", () => {
      const key = "foo";
      const cache = new FileSystemCache({ basePath: BASE_PATH });
      const path = `${ ABSOLUTE_BASE_PATH }/${ f.hash(key) }`;
      expect(cache.path(key)).to.equal(path);
    });

    it("returns a path with a namespace", () => {
      const key = "foo";
      const ns = [1, 2];
      const cache = new FileSystemCache({ basePath: BASE_PATH, ns: ns });
      const path = `${ ABSOLUTE_BASE_PATH }/${ f.hash(ns) }-${ f.hash(key) }`;
      expect(cache.path(key)).to.equal(path);
    });

    it("returns a path with a file extension", () => {
      const key = "foo";
      const path = `${ ABSOLUTE_BASE_PATH }/${ f.hash(key) }.styl`;
      let cache;
      cache = new FileSystemCache({ basePath: BASE_PATH, extension: "styl" });
      expect(cache.path(key)).to.equal(path);

      cache = new FileSystemCache({ basePath: BASE_PATH, extension: ".styl" });
      expect(cache.path(key)).to.equal(path);
    });
  });


  describe("ensureBasePath()", function() {
    it("creates the base path", (done) => {
      const cache = new FileSystemCache({ basePath: BASE_PATH });
      expect(fs.existsSync(cache.basePath)).to.equal(false);
      expect(cache.basePathExists).not.to.equal(true);
      cache.ensureBasePath()
      .then(() => {
          expect(cache.basePathExists).to.equal(true);
          expect(fs.existsSync(cache.basePath)).to.equal(true);
          done();
      })
      .catch(err => console.error(err));
    });
  });
});
