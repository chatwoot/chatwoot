import * as webpack from 'webpack';
import { TSInstance } from './interfaces';
export declare function getTSInstanceFromCache(key: webpack.Compiler, name: string): TSInstance | undefined;
export declare function setTSInstanceInCache(key: webpack.Compiler, name: string, instance: TSInstance): void;
//# sourceMappingURL=instance-cache.d.ts.map