var postcss = require('postcss');

module.exports = postcss.plugin('postcss-media-minmax', function () {
  return function(css) {
    var feature_unit = {
      'width': 'px',
      'height': 'px',
      'device-width': 'px',
      'device-height': 'px',
      'aspect-ratio': '',
      'device-aspect-ratio': '',
      'color': '',
      'color-index': '',
      'monochrome': '',
      'resolution': 'dpi'
    };

    //支持 min-/max- 前缀的属性
    var feature_name = Object.keys(feature_unit);

    var step = .001; // smallest even number that won’t break complex queries (1in = 96px)

    var power = {
      '>': 1,
      '<': -1
    };

    var minmax = {
      '>': 'min',
      '<': 'max'
    };

    function create_query(name, gtlt, eq, value, params) {
      return value.replace(/([-\d\.]+)(.*)/, function (match, number, unit) {
        var initialNumber = parseFloat(number);

        if (parseFloat(number) || eq) {
          // if eq is true, then number remains same
          if (!eq) {
            // change integer pixels value only on integer pixel
            if (unit === 'px' && initialNumber === parseInt(number, 10)) {
              number = initialNumber + power[gtlt];
            } else {
              number = Number(Math.round(parseFloat(number) + step * power[gtlt] + 'e6')+'e-6');
            }
          }
        } else {
          number = power[gtlt] + feature_unit[name];
        }

        return '(' + minmax[gtlt] + '-' + name + ': ' + number + unit + ')';
      });
    }

    // 读取 media-feature
    css.walkAtRules(function(rule, i) {
      if (rule.name !== "media" && rule.name !== "custom-media") {
        return
      }

      /**
       * 转换 <mf-name> <|>= <mf-value>
       *    $1  $2   $3
       * (width >= 300px) => (min-width: 300px)
       * (width <= 900px) => (max-width: 900px)
       */

      //取值不支持负值
      //But -0 is always equivalent to 0 in CSS, and so is also accepted as a valid <mq-boolean> value.

      rule.params = rule.params.replace(/\(\s*([a-z-]+?)\s*([<>])(=?)\s*((?:-?\d*\.?(?:\s*\/?\s*)?\d+[a-z]*)?)\s*\)/gi, function($0, $1, $2, $3, $4) {

        var params = '';

        if (feature_name.indexOf($1) > -1) {
          return create_query($1, $2, $3, $4, rule.params);
        }
        //如果不是指定的属性，不做替换
        return $0;
      })

      /**
       * 转换  <mf-value> <|<= <mf-name> <|<= <mf-value>
       * 转换  <mf-value> >|>= <mf-name> >|>= <mf-value>
       *   $1  $2$3 $4  $5$6  $7
       * (500px <= width <= 1200px) => (min-width: 500px) and (max-width: 1200px)
       * (500px < width <= 1200px) => (min-width: 501px) and (max-width: 1200px)
       * (900px >= width >= 300px)  => (min-width: 300px) and (max-width: 900px)
       */

      rule.params = rule.params.replace(/\(\s*((?:-?\d*\.?(?:\s*\/?\s*)?\d+[a-z]*)?)\s*(<|>)(=?)\s*([a-z-]+)\s*(<|>)(=?)\s*((?:-?\d*\.?(?:\s*\/?\s*)?\d+[a-z]*)?)\s*\)/gi, function($0, $1, $2, $3, $4, $5, $6, $7) {

        if (feature_name.indexOf($4) > -1) {
          if ($2 === '<' && $5 === '<' || $2 === '>' && $5 === '>') {
            var min = ($2 === '<') ? $1 : $7;
            var max = ($2 === '<') ? $7 : $1;

            // output differently depended on expression direction
            // <mf-value> <|<= <mf-name> <|<= <mf-value>
            // or
            // <mf-value> >|>= <mf-name> >|>= <mf-value>
            var equals_for_min = $3;
            var equals_for_max = $6;

            if ($2 === '>') {
              equals_for_min = $6;
              equals_for_max = $3;
            }

            return create_query($4, '>', equals_for_min, min) + ' and ' + create_query($4, '<', equals_for_max, max);
          }
        }
        //如果不是指定的属性，不做替换
        return $0;

      });

    });

  }
});
