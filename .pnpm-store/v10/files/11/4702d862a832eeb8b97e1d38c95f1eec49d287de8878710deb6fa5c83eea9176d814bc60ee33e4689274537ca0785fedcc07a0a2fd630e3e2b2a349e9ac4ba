import {InputRule} from "./inputrules"

/// Converts double dashes to an emdash.
export const emDash = new InputRule(/--$/, "—")
/// Converts three dots to an ellipsis character.
export const ellipsis = new InputRule(/\.\.\.$/, "…")
/// “Smart” opening double quotes.
export const openDoubleQuote = new InputRule(/(?:^|[\s\{\[\(\<'"\u2018\u201C])(")$/, "“")
/// “Smart” closing double quotes.
export const closeDoubleQuote = new InputRule(/"$/, "”")
/// “Smart” opening single quotes.
export const openSingleQuote = new InputRule(/(?:^|[\s\{\[\(\<'"\u2018\u201C])(')$/, "‘")
/// “Smart” closing single quotes.
export const closeSingleQuote = new InputRule(/'$/, "’")

/// Smart-quote related input rules.
export const smartQuotes: readonly InputRule[] = [openDoubleQuote, closeDoubleQuote, openSingleQuote, closeSingleQuote]
