$(document).foundation();

// [TODO] Remove this when possible
$(function() {
  // Equalizer test
  var counter = 0;
  $('#test-eq').on('postEqualized.zf.Equalizer', function() {
    counter++;
    console.log(counter);
  });
  $('#pokemonRed').on('invalid.fndtn.abide', function(e, data) {
    console.log(data);
  });
});

$(function() {
  $('[data-docs-version]').text('v' + Foundation.version);
});

var ACCORDION_KEY = 'docs-accordion-expandall';
var expandAccordion = function($a) {
  $a.parent('.accordion').find('.accordion-item, .accordion-content').addClass('is-active');
  $a.text('Collapse');
  $a.data('expandAll', false);
  if(localStorage) { localStorage.setItem(ACCORDION_KEY, 'true'); }
};

var contractAccordion = function($a) {
  $a.parent('.accordion').find('.accordion-item, .accordion-content').removeClass('is-active');
  $a.text('Expand');
  $a.data('expandAll', true);
  if(localStorage) { localStorage.setItem(ACCORDION_KEY, 'false'); }
};

$('[data-expand-all]').on('click', function() {
  var $a = $(this);
  if ($a.data().expandAll === true) {
    expandAccordion($a);
  } else {
    contractAccordion($a);
  }
});

if(localStorage.getItem(ACCORDION_KEY) === 'true') {
  expandAccordion($('[data-expand-all]'));
} else {
  $('[data-expand-all]').text('Expand');
}
