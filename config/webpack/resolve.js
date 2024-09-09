const path = require('path');

const resolve = {
  extensions: ['.js', '.vue'],
  alias: {
    vue$: 'vue/dist/vue.common.js',
    dashboard: path.resolve('./app/javascript/dashboard'),
    widget: path.resolve('./app/javascript/widget'),
    survey: path.resolve('./app/javascript/survey'),
    assets: path.resolve('./app/javascript/dashboard/assets'),
    components: path.resolve('./app/javascript/dashboard/components'),
    helpers: path.resolve('./app/javascript/shared/helpers'),
  },
};

module.exports = resolve;
