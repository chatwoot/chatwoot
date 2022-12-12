import { TSESTree } from '@typescript-eslint/types';
import { Scope } from './Scope';
import { ScopeBase } from './ScopeBase';
import { ScopeType } from './ScopeType';
import { ScopeManager } from '../ScopeManager';
declare class ClassStaticBlockScope extends ScopeBase<ScopeType.classStaticBlock, TSESTree.Expression, Scope> {
    constructor(scopeManager: ScopeManager, upperScope: ClassStaticBlockScope['upper'], block: ClassStaticBlockScope['block']);
}
export { ClassStaticBlockScope };
//# sourceMappingURL=ClassStaticBlockScope.d.ts.map