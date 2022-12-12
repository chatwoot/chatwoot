"use strict";

var _ = require(".");

describe('properties', function () {
  it('type PropertyTypes.TEXT', function () {
    expect(function () {
      var prop = {
        type: _.PropertyTypes.TEXT
      };
      return prop.type === 'text';
    }).toBeTruthy();
  });
});