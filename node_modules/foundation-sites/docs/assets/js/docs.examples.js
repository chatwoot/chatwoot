// Code for specific docs examples.

!function() {

$('[data-docs-example-ofc]').click(function() {
  $('#offCanvasLeft').toggleClass('reveal-for-large');
  $('.sticky').foundation('_calc', true);
});

$('[data-docs-example-series]').click(function() {
  $('#series-example').addClass('is-animating');
});

var $transitionDemo = $('.docs-transition-demo');
$('.docs-transitions').change(function() {
  var value = $(this).val();
  var method = value.match('-in') ? 'animateIn' : 'animateOut';

  Foundation.Motion[method]($transitionDemo, value, function() {
    $transitionDemo.show();
  });
});
var stickyMag = $('#sticky-magellan');
stickyMag.on('sticky.zf.stuckto:top', function(){
  stickyMag.find('nav').addClass('stuck-mag');
}).on('sticky.zf.unstuckfrom:top', function(e){
  stickyMag.find('nav').removeClass('stuck-mag');
});

}();
