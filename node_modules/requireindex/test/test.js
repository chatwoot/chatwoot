var Assert = require('assert');
var Asserts = require('asserts');

Asserts(function () {
  var lib = require('./lib');

  return {
    "requireindex should": {
      "properly include files parallel to index.js and maintain structure": function () {
        Asserts.all.equal([
          [lib.bam.m,            [], "ok"],
          [lib.bar.f,            [], "yea"],
          [lib.bar.fing,         [], 'definitely'],
          [lib.Foo.l,            [], 'yes'],
          [lib.Foo.ls,           [], 'yep'],
          [lib.bam.n,            [], 'ack'],
          [lib.bar.fed.again,    [], 'again'],
          [lib.bar.fed.somemore, [], 'somemore']
        ]);
      },

      "ignore _ prefixed files": function () {
        Assert.equal(('_private' in lib), false);
      },

      "not include files not mentioned when second array argument is used": function () {
        Assert.equal(('ignored' in lib.bar.fed), false);
      },

      "ignore non javascript files": function () {
        Assert.equal(('not_javascript' in lib), false);
      },

      "sort files by lowercase alpha of the filename": function () {
        Assert.equal(Object.keys(lib)[0], 'bam');
      },
      
      "ignore dot files": function () {
        Assert.equal(('.also_private' in lib), false);
      },
    }
  };
});