const definitions = [
  {
    name: 'NA',
    value: 'inapplicable',
    priority: 0,
    group: 'inapplicable'
  },
  {
    name: 'PASS',
    value: 'passed',
    priority: 1,
    group: 'passes'
  },
  {
    name: 'CANTTELL',
    value: 'cantTell',
    priority: 2,
    group: 'incomplete'
  },
  {
    name: 'FAIL',
    value: 'failed',
    priority: 3,
    group: 'violations'
  }
];

const constants = {
  helpUrlBase: 'https://dequeuniversity.com/rules/',
  results: [],
  resultGroups: [],
  resultGroupMap: {},
  impact: Object.freeze(['minor', 'moderate', 'serious', 'critical']),
  preload: Object.freeze({
    /**
     * array of supported & preload(able) asset types.
     */
    assets: ['cssom', 'media'],
    /**
     * timeout value when resolving preload(able) assets
     */
    timeout: 10000
  }),
  allOrigins: '<unsafe_all_origins>',
  sameOrigin: '<same_origin>'
};

definitions.forEach(definition => {
  const name = definition.name;
  const value = definition.value;
  const priority = definition.priority;
  const group = definition.group;

  constants[name] = value;
  constants[name + '_PRIO'] = priority;
  constants[name + '_GROUP'] = group;

  constants.results[priority] = value;
  constants.resultGroups[priority] = group;

  constants.resultGroupMap[value] = group;
});

// Freeze everything
Object.freeze(constants.results);
Object.freeze(constants.resultGroups);
Object.freeze(constants.resultGroupMap);
Object.freeze(constants);

export default constants;
