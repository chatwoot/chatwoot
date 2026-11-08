package intake

import (
	"regexp"
	"slices"
	"strings"
)

// Action is what to do with a classified piece.
type Action string

// Actions.
const (
	ActionAdd       Action = "add"       // new knowledge document, live
	ActionUpdate    Action = "update"    // same source key: replace in place, live
	ActionDuplicate Action = "duplicate" // same facts already there: keep one, note the source
	ActionProfile   Action = "profile"   // set a business profile field, live
	ActionQueue     Action = "queue"     // wait for the owner's approval
	ActionReject    Action = "reject"    // private data: not stored anywhere
	ActionDrop      Action = "drop"      // unrelated: not stored, listed in the result
)

// Suggest is the queue's recommendation for a conflict.
type Suggest string

// Suggestions.
const (
	SuggestKeep    Suggest = "keep"    // the existing version comes from a more trusted source
	SuggestReplace Suggest = "replace" // the new version comes from a source at least as trusted
)

// SimilarScore is when an existing document is about the same thing (the
// same threshold the knowledge base uses to refuse near-copies).
const SimilarScore = 0.85

// Match is an existing knowledge document similar to a piece.
type Match struct {
	DocumentID int64
	Key        string
	Title      string
	Content    string
	Source     Source
	Score      float64
}

// Decision is where a piece goes.
type Decision struct {
	Action  Action
	Field   string  // business profile field for ActionProfile (or a queued profile change)
	MatchID int64   // the existing document for update, duplicate or conflict
	Suggest Suggest // for a queued conflict
	Reason  string  // shown to the owner and to the AI app
}

var profileField = map[Label]string{LabelAbout: "about", LabelTone: "tone", LabelRules: "rules", LabelContact: "contact"}

// Decide routes one classified piece. matches are the most similar existing
// documents, best first; only knowledge pieces use them.
func Decide(it Item, matches []Match) Decision {
	switch it.Label {
	case LabelPrivate:
		why := "it looks like private data"
		if len(it.Signals.Private) > 0 {
			why += " (" + strings.Join(it.Signals.Private, ", ") + ")"
		}
		return Decision{Action: ActionReject, Reason: "refused: " + why + "; it is not stored"}
	case LabelIrrelevant:
		return Decision{Action: ActionDrop, Reason: "not something customers need"}
	case LabelReview:
		return Decision{Action: ActionQueue, Reason: "could not be sorted automatically; please choose where it goes"}
	case LabelContact:
		return Decision{Action: ActionQueue, Field: "contact", Reason: "contact and payment details need your approval"}
	}
	if len(it.Signals.Payment) > 0 {
		return Decision{Action: ActionQueue, Field: profileField[it.Label],
			Reason: "contains payment details (" + strings.Join(it.Signals.Payment, ", ") + "); payment details need your approval"}
	}
	if len(it.Signals.Contact) > 0 && !it.Source.ownerWritten() {
		return Decision{Action: ActionQueue, Field: profileField[it.Label],
			Reason: "contains contact details (" + strings.Join(it.Signals.Contact, ", ") + ") from " + it.Source.describe() + "; they need your approval"}
	}
	if field, ok := profileField[it.Label]; ok {
		if !it.Source.ownerWritten() {
			return Decision{Action: ActionQueue, Field: field, Reason: "a change to the bot's " + field + " from " + it.Source.describe() + " needs your approval"}
		}
		return Decision{Action: ActionProfile, Field: field}
	}
	return decideKnowledge(it, matches)
}

func decideKnowledge(it Item, matches []Match) Decision {
	if len(matches) == 0 || matches[0].Score < SimilarScore {
		return Decision{Action: ActionAdd}
	}
	best := matches[0]
	if it.Key != "" && it.Key == best.Key {
		return Decision{Action: ActionUpdate, MatchID: best.DocumentID}
	}
	if slices.Equal(facts(it.Title+" "+it.Content), facts(best.Title+" "+best.Content)) {
		return Decision{Action: ActionDuplicate, MatchID: best.DocumentID, Reason: "already in the knowledge base with the same details"}
	}
	d := Decision{Action: ActionQueue, MatchID: best.DocumentID, Suggest: SuggestReplace,
		Reason: "conflicts with an existing document from " + best.Source.describe() + " (different details)"}
	if best.Source.rank() < it.Source.rank() {
		d.Suggest = SuggestKeep
	}
	return d
}

var (
	number = regexp.MustCompile(`\d[\d,]*(?:\.\d+)?`)
	url    = regexp.MustCompile(`(?i)https?://[^\s<>"')]+`)
)

// facts are the details that make two similar texts disagree: numbers
// (prices, dates, quantities, without thousands separators) and links.
func facts(s string) []string {
	var out []string
	for _, u := range url.FindAllString(s, -1) {
		out = append(out, strings.TrimRight(strings.ToLower(u), "/.,"))
	}
	s = url.ReplaceAllString(s, " ")
	for _, n := range number.FindAllString(s, -1) {
		out = append(out, strings.TrimRight(strings.ReplaceAll(n, ",", ""), "."))
	}
	slices.Sort(out)
	return slices.Compact(out)
}
