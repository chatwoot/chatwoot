// Package intake sorts incoming business information (an uploaded file, an
// AI app over MCP, a synced Google Sheet or web page) into where it belongs:
// the knowledge base, a business profile field, the owner's approval queue,
// or nowhere (private data, unrelated text). Part of DEV-Johnstocker/chatwoot#1.
//
// The order matters for safety: pattern checks run first, so private data
// (card numbers, passwords, ID numbers) is refused before any text is sent
// to a model; the model only labels the rest; and the routing rules, not the
// model, decide what goes live. Payment and contact details never go live
// without the owner's approval, whatever the model says.
package intake

import "context"

// Source is where a piece of information came from.
type Source string

// Sources, most trusted first.
const (
	SourceOwner  Source = "owner"  // the owner editing on /admin
	SourceSheet  Source = "sheet"  // the owner's synced data file
	SourceUpload Source = "upload" // a file uploaded on /admin
	SourceAI     Source = "ai"     // an AI app over MCP
	SourceWeb    Source = "web"    // a synced web page
)

// rank orders sources by trust; lower is more trusted.
func (s Source) rank() int {
	switch s {
	case SourceOwner:
		return 0
	case SourceSheet:
		return 1
	case SourceUpload:
		return 2
	case SourceAI:
		return 3
	}
	return 4
}

// ownerWritten reports whether the owner wrote this directly (not an AI app
// or a web page someone else controls).
func (s Source) ownerWritten() bool { return s.rank() <= SourceUpload.rank() }

func (s Source) describe() string {
	switch s {
	case SourceAI:
		return "an AI app"
	case SourceWeb:
		return "a web page"
	case SourceSheet:
		return "the synced data file"
	case SourceUpload:
		return "an uploaded file"
	}
	return "the owner"
}

// Label is what a piece of information is.
type Label string

// Labels.
const (
	LabelKnowledge  Label = "knowledge"  // FAQ, product, price, policy, how-to
	LabelAbout      Label = "about"      // what the business is and sells
	LabelTone       Label = "tone"       // how the bot should sound
	LabelRules      Label = "rules"      // do and don't rules for the bot
	LabelContact    Label = "contact"    // how to pay, buy or reach staff
	LabelPrivate    Label = "private"    // secrets or a person's private data
	LabelIrrelevant Label = "irrelevant" // nothing a customer would need
	LabelReview     Label = "review"     // could not be sorted; the owner decides
)

// Piece is one unit of incoming information.
type Piece struct {
	Key     string // stable key from the source (feed row, page), if any
	Title   string
	Content string
}

// Item is a classified piece.
type Item struct {
	Piece
	Label   Label
	Signals Signals
	Source  Source
}

// Labeler labels pieces (LLMLabeler); one label per piece, in order.
type Labeler interface {
	Label(ctx context.Context, pieces []Piece) ([]Label, error)
}

// Classify runs the pattern checks, refuses private pieces without showing
// them to the labeler, and labels the rest. A labeler failure sends the
// pieces to the owner for review rather than guessing.
func Classify(ctx context.Context, l Labeler, pieces []Piece, src Source) []Item {
	items := make([]Item, len(pieces))
	var ask []Piece
	var at []int
	for i, p := range pieces {
		items[i] = Item{Piece: p, Source: src, Signals: Detect(p.Title + "\n" + p.Content)}
		if len(items[i].Signals.Private) > 0 {
			items[i].Label = LabelPrivate
			continue
		}
		ask, at = append(ask, p), append(at, i)
	}
	if len(ask) == 0 {
		return items
	}
	labels, err := l.Label(ctx, ask)
	for j, i := range at {
		if err != nil || j >= len(labels) {
			items[i].Label = LabelReview
			continue
		}
		items[i].Label = labels[j]
	}
	return items
}
