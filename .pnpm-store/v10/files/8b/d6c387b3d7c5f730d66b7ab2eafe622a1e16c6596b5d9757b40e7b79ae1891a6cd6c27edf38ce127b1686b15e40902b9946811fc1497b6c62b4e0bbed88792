import {
	character,
	MatchTree
} from './AsYouTypeFormatter.PatternParser.d.js'

interface MatchOptions {
	allowOverflow?: boolean;
}

// An "overflow" match is when the string matches the pattern
// and there're still some characters left in it.
//
// For example, "12345" matches "12[0-5]|78" pattern with an overflow
// because "123" matches the "12[0-5]" variant of the pattern
// and there're still "45" characters left.
//
// This type of match is only returned when `allowOverflow` option is `true`.
// By default, `allowOverflow` is `false` and `undefined` ("no match" result)
// is returned in case of an "overflow" match.
//
interface MatchResultOverflow {
	overflow: true;
}

// When there's a ("full") match, returns a match result.
//
// A ("full") match is when the string matches the entire pattern.
//
// For example, "123" fully matches "12[0-5]|78" pattern.
//
interface MatchResultFullMatch {
	match: true;
	matchedChars: character[];
}

// When there's a "partial" match, returns a "partial" match result.
//
// A "partial" match is when the string is not long enough
// to match the whole matching tree.
//
// For example, "123" is a partial match for "12[0-5]4|78" pattern,
// because "123" matched the "12[0-5]" part and the "4" part of the pattern
// is left uninvolved.
//
interface MatchResultPartialMatch {
	partialMatch: true;
}

// When there's no match, returns `undefined`.
//
// For example, "123" doesn't match "456|789" pattern.
//
type MatchResultNoMatch = undefined;

type MatchResult =
	MatchResultOverflow |
	MatchResultFullMatch |
	MatchResultPartialMatch |
	MatchResultNoMatch;

export default class PatternMatcher {
	constructor(pattern: string);
	match(string: string, options?: MatchOptions): MatchResult;
}

function match(characters: character[], tree: MatchTree, last?: boolean);
