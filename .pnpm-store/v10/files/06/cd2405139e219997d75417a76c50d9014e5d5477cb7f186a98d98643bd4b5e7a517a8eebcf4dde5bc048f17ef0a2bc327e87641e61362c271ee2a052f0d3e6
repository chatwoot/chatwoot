var removeDiacritics = require('../').remove,
    assert = require('assert');

assert.strictEqual(removeDiacritics("Iлｔèｒｎåｔïｏｎɑｌíƶａｔï߀ԉ"),
    "Internationalizati0n");
assert.strictEqual(removeDiacritics("Båｃòл íｐѕùｍ ðｏɭ߀ｒ ѕïｔ ａϻèｔ âùþê ａԉᏧ߀üïｌɭê ƃëéｆ ｃｕｌρá ｆïｌèｔ ϻｉǥｎòｎ ｃｕρｉᏧａｔａｔ ｕｔ êлｉｍ ｔòлɢùê."),
    "Bacon ipѕum dhol0r ѕit aMet authe and0uille beef culpa filet Mignon cupidatat ut enim tonGue.");
assert.strictEqual(removeDiacritics("ᴎᴑᴅᴇȷʂ"), "NoDEJs");

assert.strictEqual(removeDiacritics("hambúrguer"), "hamburguer");
assert.strictEqual(removeDiacritics("hŒllœ"), "hOElloe");
assert.strictEqual(removeDiacritics("Fußball"), "Fussball");

assert.strictEqual(removeDiacritics("ABCDEFGHIJKLMNOPQRSTUVWXYZé"), "ABCDEFGHIJKLMNOPQRSTUVWXYZe");
