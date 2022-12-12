describe('Magellan', function() {
	var plugin;
	var $html, $content;

  var generateUl = function(count) {
  	var html = '';
  	html += '<ul class="vertical-menu">';
  	for (var c = 0; c < count; c++) {
  		html += '<li><a href="#target-' + c + '">Section ' + c + '</a></li>';
  	}
  	html += '</ul>';
  	return html;
  };
  var generateContent = function(count) {
  	var html = '';
  	html += '<div>';
  	for (var c = 0; c < count; c++) {
  		html += '<div id="target-' + c + '" style="height: 1000px";>Section ' + c + '</div>';
  	}
  	html += '</div>';
  	return html;
  };

  afterEach(function() {
    plugin.destroy();
    $html.remove();
    $content.remove();
  });

	// afterEach(function() {
	// 	plugin.destroy();
	// 	$html.remove();
	// });

	describe('constructor()', function() {
		// it('', function() {
		// 	$html = $('').appendTo('body');
		// 	plugin = new Foundation.Magellan($html, {});

		// 	plugin.$element.should.be.an('object');
		// 	plugin.options.should.be.an('object');
		// });
	});


	describe('scrollToLoc()', function() {
    it('scrolls the selected element into viewport', function(done) {
    	var count = 5, duration = 200;
      $html = $(generateUl(count)).appendTo('body');
      $content = $(generateContent(count)).appendTo('body');
      plugin = new Foundation.Magellan($html, {
      	animationDuration: duration
      });

      // Jump to last section
      var target = $html.find('a').eq(-1).attr('href');
      plugin.scrollToLoc(target);

      setTimeout(function() {
        var isInViewport = false;
        if ($content.find('div').eq(-1).offset().top > $('body').scrollTop() && $content.offset().top < $('body').scrollTop() + $('body').innerHeight()) {
          isInViewport = true;
        }
        isInViewport.should.equal(true);
        done();
      }, duration);

    });


    it('fails gracefully when target does not exist', function() {
    	var count = 5, duration = 200;
      $html = $(generateUl(count)).appendTo('body');
      $content = $(generateContent(count - 1)).appendTo('body');
      plugin = new Foundation.Magellan($html, {
      	animationDuration: duration
      });

      var hasError = false;
      var targets = $html.find('a');
      try {
        var target = $(targets).eq(-1).attr('href');
        plugin.scrollToLoc(target);
      }
      catch (err) {
        hasError = true;
      }
      hasError.should.equal(false);
    });

  });

});
