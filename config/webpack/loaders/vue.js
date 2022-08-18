module.exports = {
  test: /\.vue(\.erb)?$/,
  use: [{
    loader: 'vue-loader',
    options: {
      compilerOptions: {
        compatConfig: {
          MODE: 2,
        },
      },
    },
  }],
};
