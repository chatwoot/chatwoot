var postcss = require('postcss');

module.exports = postcss.plugin('postcss-page-break', function () {

    return function (root) {

        root.walkDecls(/^break-(inside|before|after)/, function (decl) {
            // do not process column|region related properties
            if (decl.value.search(/column|region/) >= 0) {
                return;
            }

            var newValue;
            switch (decl.value) {
                case 'page':
                    newValue = 'always';
                    break;
                case 'avoid-page':
                    newValue = 'avoid';
                    break;
                default:
                    newValue = decl.value;
            }

            decl.cloneBefore({
                prop: 'page-' + decl.prop,
                value: newValue
            });
        });

    };
});
