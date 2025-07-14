function getApplicableSuggestion(message, filter, context) {
    if (!message.suggestions || message.suggestions.length === 0)
        return null;
    const suggestion = filter(message.suggestions, message, context);
    return suggestion ?? null;
}
function generateFixPerMessage(context, filter, message) {
    const suggestion = getApplicableSuggestion(message, filter, context);
    if (!suggestion)
        return null;
    return suggestion.fix;
}
/**
 * Create fix to apply suggestions.
 */
export function createFixToApplySuggestions(context, args) {
    const fixes = [];
    for (const message of context.messages) {
        const fix = generateFixPerMessage(context, args.filter, message);
        if (fix)
            fixes.push(fix);
    }
    return fixes;
}
//# sourceMappingURL=apply-suggestions.js.map