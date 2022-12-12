module.exports = {
  printWidth: 80,
  trailingComma: "all",
  singleQuote: false,

  overrides: [
    {
      files: "*.md",
      options: {
        printWidth: 60,
      },
    },
  ],
};
