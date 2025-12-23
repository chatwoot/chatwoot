const config = require("@fnando/codestyle/jest");

module.exports = {
  ...config,
  testRegex: ".*?\\.test\\.ts",
  roots: ["<rootDir>/src"],
  modulePaths: ["src"],
  moduleNameMapper: {
    "^~/(.*?)$": "<rootDir>/src/$1",
  },
  testPathIgnorePatterns: ["/vendor/bundle/", "node_modules"],
};
