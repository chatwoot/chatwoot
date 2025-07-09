import chalk from 'chalk';
import table from 'table';
import terminalLink from 'terminal-link';
import { ERROR_COLOR } from './colors.js';
import { takeRuleStatistics } from './take-rule-statistics.js';
function numCell(num) {
    return num > 0 ? chalk[ERROR_COLOR].bold(num) : num.toString();
}
export function formatByRules(results, data) {
    const ruleStatistics = takeRuleStatistics(results);
    const rows = [];
    // header
    rows.push(['Rule', 'Error', 'Warning', 'is fixable', 'has suggestions']);
    ruleStatistics.forEach((ruleStatistic) => {
        const { ruleId, errorCount, warningCount, isFixableCount, hasSuggestionsCount } = ruleStatistic;
        rows.push([
            ruleId,
            numCell(errorCount),
            numCell(warningCount),
            numCell(isFixableCount),
            numCell(hasSuggestionsCount),
        ]);
    });
    // The `table` package does not print the terminal link correctly. So eslint-interactive avoids
    // this by first printing the table in the `table` package without the link,
    // then converting it to a link by replacement.
    // ref: https://github.com/gajus/table/issues/113
    let result = table.table(rows);
    ruleStatistics.forEach((ruleStatistic) => {
        const { ruleId } = ruleStatistic;
        const ruleMetaData = data?.rulesMeta[ruleId];
        const ruleCell = ruleMetaData?.docs?.url ? terminalLink(ruleId, ruleMetaData?.docs.url, { fallback: false }) : ruleId;
        result = result.replace(` ${ruleId} `, ` ${ruleCell} `);
    });
    return result;
}
//# sourceMappingURL=format-by-rules.js.map