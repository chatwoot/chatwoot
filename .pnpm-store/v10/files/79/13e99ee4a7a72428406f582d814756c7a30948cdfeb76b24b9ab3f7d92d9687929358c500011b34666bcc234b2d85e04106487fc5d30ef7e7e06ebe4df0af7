import { groupBy } from '../util/array.js';
/** 指定されたルールのエラー/警告の件数などの統計を取る */
function takeRuleStatistic(ruleId, messages) {
    let errorCount = 0;
    let warningCount = 0;
    let isFixableErrorCount = 0;
    let isFixableWarningCount = 0;
    let hasSuggestionsErrorCount = 0;
    let hasSuggestionsWarningCount = 0;
    for (const message of messages) {
        if (message.severity === 2) {
            errorCount++;
            if (message.fix)
                isFixableErrorCount++;
            if (message.suggestions && message.suggestions.length > 0)
                hasSuggestionsErrorCount++;
        }
        else if (message.severity === 1) {
            warningCount++;
            if (message.fix)
                isFixableWarningCount++;
            if (message.suggestions && message.suggestions.length > 0)
                hasSuggestionsWarningCount++;
        }
    }
    return {
        ruleId,
        errorCount,
        warningCount,
        isFixableCount: isFixableErrorCount + isFixableWarningCount,
        isFixableErrorCount,
        isFixableWarningCount,
        hasSuggestionsCount: hasSuggestionsErrorCount + hasSuggestionsWarningCount,
        hasSuggestionsErrorCount,
        hasSuggestionsWarningCount,
    };
}
/** ルールごとのエラー/警告の件数などの統計を取る */
export function takeRuleStatistics(results) {
    const messages = results.flatMap((result) => result.messages).filter((message) => message.ruleId !== null);
    const ruleIdToMessages = groupBy(messages, (message) => message.ruleId);
    const ruleStatistics = [];
    for (const [ruleId, messages] of ruleIdToMessages) {
        // NOTE: Exclude problems with a null `ruleId`.
        // ref: ref: https://github.com/eslint/eslint/blob/f1b7499a5162d3be918328ce496eb80692353a5a/docs/developer-guide/nodejs-api.md?plain=1#L372
        if (ruleId !== null)
            ruleStatistics.push(takeRuleStatistic(ruleId, messages));
    }
    return ruleStatistics;
}
//# sourceMappingURL=take-rule-statistics.js.map