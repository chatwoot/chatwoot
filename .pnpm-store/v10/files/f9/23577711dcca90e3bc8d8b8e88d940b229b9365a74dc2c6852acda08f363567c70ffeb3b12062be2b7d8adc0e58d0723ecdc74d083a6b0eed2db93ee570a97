function t(t){return "object"==typeof t&&null!=t&&1===t.nodeType}function e(t,e){return (!e||"hidden"!==t)&&"visible"!==t&&"clip"!==t}function n(t,n){if(t.clientHeight<t.scrollHeight||t.clientWidth<t.scrollWidth){var r=getComputedStyle(t,null);return e(r.overflowY,n)||e(r.overflowX,n)||function(t){var e=function(t){if(!t.ownerDocument||!t.ownerDocument.defaultView)return null;try{return t.ownerDocument.defaultView.frameElement}catch(t){return null}}(t);return !!e&&(e.clientHeight<t.scrollHeight||e.clientWidth<t.scrollWidth)}(t)}return !1}function r(t,e,n,r,i,o,l,d){return o<t&&l>e||o>t&&l<e?0:o<=t&&d<=n||l>=e&&d>=n?o-t-r:l>e&&d<n||o<t&&d>n?l-e+i:0}var i=function(e,i){var o=window,l=i.scrollMode,d=i.block,f=i.inline,h=i.boundary,u=i.skipOverflowHiddenElements,s="function"==typeof h?h:function(t){return t!==h};if(!t(e))throw new TypeError("Invalid target");for(var a,c,g=document.scrollingElement||document.documentElement,p=[],m=e;t(m)&&s(m);){if((m=null==(c=(a=m).parentElement)?a.getRootNode().host||null:c)===g){p.push(m);break}null!=m&&m===document.body&&n(m)&&!n(document.documentElement)||null!=m&&n(m,u)&&p.push(m);}for(var w=o.visualViewport?o.visualViewport.width:innerWidth,v=o.visualViewport?o.visualViewport.height:innerHeight,W=window.scrollX||pageXOffset,H=window.scrollY||pageYOffset,b=e.getBoundingClientRect(),y=b.height,E=b.width,M=b.top,V=b.right,x=b.bottom,I=b.left,C="start"===d||"nearest"===d?M:"end"===d?x:M+y/2,R="center"===f?I+E/2:"end"===f?V:I,T=[],k=0;k<p.length;k++){var B=p[k],D=B.getBoundingClientRect(),O=D.height,X=D.width,Y=D.top,L=D.right,S=D.bottom,j=D.left;if("if-needed"===l&&M>=0&&I>=0&&x<=v&&V<=w&&M>=Y&&x<=S&&I>=j&&V<=L)return T;var N=getComputedStyle(B),q=parseInt(N.borderLeftWidth,10),z=parseInt(N.borderTopWidth,10),A=parseInt(N.borderRightWidth,10),F=parseInt(N.borderBottomWidth,10),G=0,J=0,K="offsetWidth"in B?B.offsetWidth-B.clientWidth-q-A:0,P="offsetHeight"in B?B.offsetHeight-B.clientHeight-z-F:0,Q="offsetWidth"in B?0===B.offsetWidth?0:X/B.offsetWidth:0,U="offsetHeight"in B?0===B.offsetHeight?0:O/B.offsetHeight:0;if(g===B)G="start"===d?C:"end"===d?C-v:"nearest"===d?r(H,H+v,v,z,F,H+C,H+C+y,y):C-v/2,J="start"===f?R:"center"===f?R-w/2:"end"===f?R-w:r(W,W+w,w,q,A,W+R,W+R+E,E),G=Math.max(0,G+H),J=Math.max(0,J+W);else {G="start"===d?C-Y-z:"end"===d?C-S+F+P:"nearest"===d?r(Y,S,O,z,F+P,C,C+y,y):C-(Y+O/2)+P/2,J="start"===f?R-j-q:"center"===f?R-(j+X/2)+K/2:"end"===f?R-L+A+K:r(j,L,X,q,A+K,R,R+E,E);var Z=B.scrollLeft,$=B.scrollTop;C+=$-(G=Math.max(0,Math.min($+G/U,B.scrollHeight-O/U+P))),R+=Z-(J=Math.max(0,Math.min(Z+J/Q,B.scrollWidth-X/Q+K)));}T.push({el:B,top:G,left:J});}return T};

function isOptionsObject(options) {
  return options === Object(options) && Object.keys(options).length !== 0;
}
function defaultBehavior(actions, behavior) {
  if (behavior === void 0) {
    behavior = 'auto';
  }
  var canSmoothScroll = ('scrollBehavior' in document.body.style);
  actions.forEach(function (_ref) {
    var el = _ref.el,
      top = _ref.top,
      left = _ref.left;
    if (el.scroll && canSmoothScroll) {
      el.scroll({
        top: top,
        left: left,
        behavior: behavior
      });
    } else {
      el.scrollTop = top;
      el.scrollLeft = left;
    }
  });
}
function getOptions(options) {
  if (options === false) {
    return {
      block: 'end',
      inline: 'nearest'
    };
  }
  if (isOptionsObject(options)) {
    return options;
  }
  return {
    block: 'start',
    inline: 'nearest'
  };
}
function scrollIntoView(target, options) {
  var isTargetAttached = target.isConnected || target.ownerDocument.documentElement.contains(target);
  if (isOptionsObject(options) && typeof options.behavior === 'function') {
    return options.behavior(isTargetAttached ? i(target, options) : []);
  }
  if (!isTargetAttached) {
    return;
  }
  var computeOptions = getOptions(options);
  return defaultBehavior(i(target, computeOptions), computeOptions.behavior);
}

// eslint-disable-next-line import/no-named-default

export { scrollIntoView as default };
