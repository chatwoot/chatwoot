const information_for_contributors = [
	"This file has been converted from https://github.com/textmate/git.tmbundle/blob/master/Syntaxes/Git%20Rebase%20Message.tmLanguage",
	"If you want to provide a fix or improvement, please create a pull request against the original repository.",
	"Once accepted there, we are happy to receive an update request."
];
const version = "https://github.com/textmate/git.tmbundle/commit/5870cf3f8abad3a6637bdf69250b5d2ded427dc4";
const name = "git-rebase";
const scopeName = "text.git-rebase";
const patterns = [
	{
		captures: {
			"1": {
				name: "punctuation.definition.comment.git-rebase"
			}
		},
		match: "^\\s*(#).*$\\n?",
		name: "comment.line.number-sign.git-rebase"
	},
	{
		captures: {
			"1": {
				name: "support.function.git-rebase"
			},
			"2": {
				name: "constant.sha.git-rebase"
			},
			"3": {
				name: "meta.commit-message.git-rebase"
			}
		},
		match: "^\\s*(pick|p|reword|r|edit|e|squash|s|fixup|f|drop|d)\\s+([0-9a-f]+)\\s+(.*)$",
		name: "meta.commit-command.git-rebase"
	},
	{
		captures: {
			"1": {
				name: "support.function.git-rebase"
			},
			"2": {
				patterns: [
					{
						include: "source.shell"
					}
				]
			}
		},
		match: "^\\s*(exec|x)\\s+(.*)$",
		name: "meta.commit-command.git-rebase"
	},
	{
		captures: {
			"1": {
				name: "support.function.git-rebase"
			}
		},
		match: "^\\s*(break|b)\\s*$",
		name: "meta.commit-command.git-rebase"
	}
];
const gitRebase_tmLanguage = {
	information_for_contributors: information_for_contributors,
	version: version,
	name: name,
	scopeName: scopeName,
	patterns: patterns
};

export { gitRebase_tmLanguage as default, information_for_contributors, name, patterns, scopeName, version };
