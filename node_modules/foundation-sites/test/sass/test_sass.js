var path = require('path');
var sassTrue = require('sass-true');

// Test Files
var breakpointFile = path.join(__dirname, '_breakpoint.scss');
var colorFile = path.join(__dirname, '_color.scss');
var selectorFile = path.join(__dirname, '_selector.scss');
var unitFile = path.join(__dirname, '_unit.scss');
var valueFile = path.join(__dirname, '_value.scss');
var componentsFile = path.join(__dirname, '_components.scss');

// Run Tests
sassTrue.runSass({file: breakpointFile}, describe, it);
sassTrue.runSass({file: colorFile}, describe, it);
sassTrue.runSass({file: selectorFile}, describe, it);
sassTrue.runSass({file: unitFile}, describe, it);
sassTrue.runSass({file: valueFile}, describe, it);
sassTrue.runSass({file: componentsFile}, describe, it);