import { NodePath } from 'ast-types/lib/node-path';
import { ParseOptions } from '../parse';
export default function getPathOfExportedValue(pathResolver: (path: string, originalDirNameOverride?: string) => string | null, exportName: string, filePath: string[], options: ParseOptions): Promise<NodePath | undefined>;
