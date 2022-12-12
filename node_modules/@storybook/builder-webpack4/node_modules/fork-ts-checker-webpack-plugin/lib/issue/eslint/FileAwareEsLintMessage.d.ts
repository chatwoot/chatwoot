import { LintMessage } from '../../types/eslint';
/**
 * We need to define custom interface because of eslint architecture which
 * groups lint messages per file
 */
interface FileAwareEsLintMessage extends LintMessage {
    filePath?: string;
}
export { FileAwareEsLintMessage };
