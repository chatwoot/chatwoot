describe('Foundation box', function () {
  var $html;

  afterEach(function () {
    if ($html) {
      $html.remove();
    }
  });

  describe('GetDimensions()', function () {
    it('should be unable to get dimensions for window', function(done) {
      try {
        Foundation.Box.GetDimensions($("window"));

        should.fail();
      } catch (err) {
        done();
      }
    });

    it('should be unable to get dimensions for document', function(done) {
      try {
        Foundation.Box.GetDimensions($("document"));

        should.fail();
      } catch (err) {
        done();
      }
    });

    it('height and width of element', function () {
      $html = $('<div id="rect-test" style="height: 100px;width:200px;"></div>').appendTo('body');

      var dims = Foundation.Box.GetDimensions($("#rect-test"));

      dims.width.should.equal(200);
      dims.height.should.equal(100);
    });

    it('parent height of element', function () {
      $html = $('<div style="height: 200px;"><div id="rect-test-parent" style="height: 100px;width:200px;"></div></div>').appendTo('body');

      var dims = Foundation.Box.GetDimensions($("#rect-test-parent"));

      dims.width.should.equal(200);
      dims.height.should.equal(100);

      dims.parentDims.height.should.equal(200);
    });
  });
});
