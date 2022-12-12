// Kissmetrics reporting

!function() {

var _kmq = _kmq || [];
var _kmk = _kmk || "d945f04ff5e68057c85f5323b46f185efb3826b3";
function _kms(u){
  setTimeout(function(){
    var d = document, f = d.getElementsByTagName('script')[0],
    s = d.createElement('script');
    s.type = 'text/javascript'; s.async = true; s.src = u;
    f.parentNode.insertBefore(s, f);
  }, 1);
}
_kms('//i.kissmetrics.com/i.js');
_kms('//doug1izaerwt3.cloudfront.net/' + _kmk + '.1.js');

}();
