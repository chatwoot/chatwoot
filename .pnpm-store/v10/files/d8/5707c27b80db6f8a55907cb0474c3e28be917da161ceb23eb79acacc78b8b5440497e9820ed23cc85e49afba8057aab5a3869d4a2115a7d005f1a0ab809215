// A string of length `1`.
//
// Example: "3".
//
export type character = string;

// Matches any character.
//
// Example:
//
// String pattern "123" compiles into 3 characters:
//
// ["1", "2", "3"]
//
type Character = character;

// Matches one of characters.
//
// Example:
//
// String pattern "[5-9]" compiles into:
//
// { op: "[]", args: ["5", "6", "7", "8", "9"] }
//
interface OneOfCharacters {
	op: '[]';
	args: character[];
}

// Matches any of the subtrees.
//
// Example:
//
// String pattern "123|[5-9]0" compiles into:
//
// {
// 	op: "|",
// 	args: [
// 		// First subtree:
// 		["1", "2", "3"],
// 		// Second subtree:
// 		[
// 			{ op: "[]", args: ["5", "6", "7", "8", "9"] },
// 			"0"
// 		]
// 	]
// }
//
interface OrCondition<MatchTree> {
	op: '|';
	args: MatchTree[];
}

export type MatchTree = Character | OneOfCharacters | MatchTree[] | OrCondition<MatchTree>;

export default class PatternParser {
	parse(pattern: string): MatchTree;
}
