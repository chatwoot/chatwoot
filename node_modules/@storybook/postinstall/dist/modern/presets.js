export function addPreset(preset, presetOptions, {
  api,
  root
}) {
  const j = api.jscodeshift;
  const moduleExports = [];
  root.find(j.AssignmentExpression).filter(assignment => assignment.node.left.type === 'MemberExpression' && assignment.node.left.object.name === 'module' && assignment.node.left.property.name === 'exports').forEach(exp => moduleExports.push(exp));
  let exportArray = null;

  switch (moduleExports.length) {
    case 0:
      {
        exportArray = j.arrayExpression([]);
        const exportStatement = j.assignmentStatement('=', j.memberExpression(j.identifier('module'), j.identifier('exports')), exportArray);
        root.get().node.program.body.push(exportStatement);
        break;
      }

    case 1:
      exportArray = moduleExports[0].node.right;
      break;

    default:
      throw new Error('Multiple module export statements');
  }

  let presetConfig = j.literal(preset);

  if (presetOptions) {
    const optionsJson = `const x = ${JSON.stringify(presetOptions)}`;
    const optionsRoot = j(optionsJson);
    const optionsNode = optionsRoot.find(j.VariableDeclarator).get().node.init;
    presetConfig = j.objectExpression([j.property('init', j.identifier('name'), j.literal(preset)), j.property('init', j.identifier('options'), optionsNode)]);
  }

  exportArray.elements.push(presetConfig);
}