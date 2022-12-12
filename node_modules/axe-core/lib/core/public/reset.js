import { resetStandards } from '../../standards';

function reset() {
  var audit = axe._audit;

  if (!audit) {
    throw new Error('No audit configured');
  }
  audit.resetRulesAndChecks();
  resetStandards();
}

export default reset;
