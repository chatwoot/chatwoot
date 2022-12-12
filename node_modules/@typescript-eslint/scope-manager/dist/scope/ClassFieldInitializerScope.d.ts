import { TSESTree } from '@typescript-eslint/types';
import { Scope } from './Scope';
import { ScopeBase } from './ScopeBase';
import { ScopeType } from './ScopeType';
import { ScopeManager } from '../ScopeManager';
declare class ClassFieldInitializerScope extends ScopeBase<ScopeType.classFieldInitializer, TSESTree.Expression, Scope> {
    constructor(scopeManager: ScopeManager, upperScope: ClassFieldInitializerScope['upper'], block: ClassFieldInitializerScope['block']);
}
export { ClassFieldInitializerScope };
//# sourceMappingURL=ClassFieldInitializerScope.d.ts.map