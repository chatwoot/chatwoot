import {InputRule} from "./inputrules"

// :: InputRule Converts double dashes to an emdash.
export const emDash = new InputRule(/--$/, "—")
// :: InputRule Converts three dots to an ellipsis character.
export const ellipsis = new InputRule(/\.\.\.$/, "…")
// :: InputRule “Smart” opening double quotes.
export const openDoubleQuote = new InputRule(/(?:^|[\s\{\[\(\<'"\u2018\u201C])(")$/, "“")
// :: InputRule “Smart” closing double quotes.
export const closeDoubleQuote = new InputRule(/"$/, "”")
// :: InputRule “Smart” opening single quotes.
export const openSingleQuote = new InputRule(/(?:^|[\s\{\[\(\<'"\u2018\u201C])(')$/, "‘")
// :: InputRule “Smart” closing single quotes.
export const closeSingleQuote = new InputRule(/'$/, "’")

// :: [InputRule] Smart-quote related input rules.
export const smartQuotes = [openDoubleQuote, closeDoubleQuote, openSingleQuote, closeSingleQuote]
