const path = require('path');

const resolve = {
  extensions: ['.js', '.vue'],
  alias: {
    vue: '@vue/compat',
    dashboard: path.resolve('./app/javascript/dashboard'),
    widget: path.resolve('./app/javascript/widget'),
    survey: path.resolve('./app/javascript/survey'),
    assets: path.resolve('./app/javascript/dashboard/assets'),
    components: path.resolve('./app/javascript/dashboard/components'),
  },
};

module.exports = resolve;
