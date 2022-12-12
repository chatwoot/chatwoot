/* global describe, it, expect, axe, document */

describe('axe', function() {
  'use strict';

  document
    .getElementsByTagName('body')[0]
    .insertAdjacentHTML(
      'beforeend',
      '<div id="working">' +
        '<label for="has-label">Label for this text field.</label>' +
        '<input type="text" id="has-label">' +
        '</div>' +
        '<div id="broken">' +
        '<p>Not a label</p><input type="text" id="no-label">' +
        '</div>'
    );

  it('should report that good HTML is good', function(done) {
    var n = document.getElementById('working');
    axe.run(n, function(err, result) {
      expect(err).toBe(null);
      expect(result.violations.length).toBe(0);
      done();
    });
  });

  it('should report that bad HTML is bad', function(done) {
    var n = document.getElementById('broken');
    axe.run(n, function(err, result) {
      expect(err).toBe(null);
      expect(result.violations.length).toBe(1);
      done();
    });
  });
});
