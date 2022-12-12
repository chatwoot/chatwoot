import Documentation from './Documentation';
import { ParseOptions } from './parse';
export default function parseSFC(initialDoc: Documentation | undefined, source: string, opt: ParseOptions): Promise<Documentation[]>;
