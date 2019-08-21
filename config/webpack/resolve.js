const path = require('path');

const resolve = {
  extensions: ['', '.js', '.vue'],
  alias: {
    vue$: 'vue/dist/vue.common.js',
    src: path.resolve('./app/javascript/src'),
    assets: path.resolve('./app/javascript/src/assets'),
    components: path.resolve('./app/javascript/src/components'),
  },
};

module.exports = resolve;
