module.exports = {
  test: /\.vue(\.erb)?$/,
  loader: 'vue-loader',
  options: {
    compilerOptions: {
      compatConfig: {
        MODE: 2,
      },
    },
  },
};
