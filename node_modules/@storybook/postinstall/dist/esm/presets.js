import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.array.find.js";
import "core-js/modules/es.function.name.js";
export function addPreset(preset, presetOptions, _ref) {
  var api = _ref.api,
      root = _ref.root;
  var j = api.jscodeshift;
  var moduleExports = [];
  root.find(j.AssignmentExpression).filter(function (assignment) {
    return assignment.node.left.type === 'MemberExpression' && assignment.node.left.object.name === 'module' && assignment.node.left.property.name === 'exports';
  }).forEach(function (exp) {
    return moduleExports.push(exp);
  });
  var exportArray = null;

  switch (moduleExports.length) {
    case 0:
      {
        exportArray = j.arrayExpression([]);
        var exportStatement = j.assignmentStatement('=', j.memberExpression(j.identifier('module'), j.identifier('exports')), exportArray);
        root.get().node.program.body.push(exportStatement);
        break;
      }

    case 1:
      exportArray = moduleExports[0].node.right;
      break;

    default:
      throw new Error('Multiple module export statements');
  }

  var presetConfig = j.literal(preset);

  if (presetOptions) {
    var optionsJson = "const x = ".concat(JSON.stringify(presetOptions));
    var optionsRoot = j(optionsJson);
    var optionsNode = optionsRoot.find(j.VariableDeclarator).get().node.init;
    presetConfig = j.objectExpression([j.property('init', j.identifier('name'), j.literal(preset)), j.property('init', j.identifier('options'), optionsNode)]);
  }

  exportArray.elements.push(presetConfig);
}