package intake

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type fakeLabeler struct {
	labels []Label
	err    error
	seen   []Piece
}

func (f *fakeLabeler) Label(_ context.Context, pieces []Piece) ([]Label, error) {
	f.seen = append(f.seen, pieces...)
	if f.err != nil {
		return nil, f.err
	}
	return f.labels[:len(pieces)], nil
}

func TestClassify_PrivateTextNeverReachesTheModel(t *testing.T) {
	// Arrange
	l := &fakeLabeler{labels: []Label{LabelKnowledge, LabelKnowledge}}
	pieces := []Piece{{Title: "card", Content: "บัตร 4111 1111 1111 1111"}, {Title: "price", Content: "ราคา 3,900 บาท"}}

	// Act
	items := Classify(context.Background(), l, pieces, SourceUpload)

	// Assert
	if len(l.seen) != 1 || l.seen[0].Title != "price" {
		t.Fatalf("model saw %+v, want only the price piece", l.seen)
	}
	if items[0].Label != LabelPrivate || items[1].Label != LabelKnowledge {
		t.Fatalf("labels = %v, %v", items[0].Label, items[1].Label)
	}
}

func TestClassify_ModelFailureSendsToReview(t *testing.T) {
	// Arrange
	l := &fakeLabeler{err: errors.New("timeout")}

	// Act
	items := Classify(context.Background(), l, []Piece{{Title: "x", Content: "ราคา 3,900 บาท"}}, SourceUpload)

	// Assert
	if items[0].Label != LabelReview {
		t.Fatalf("label = %v, want review", items[0].Label)
	}
}

func TestDecide(t *testing.T) {
	price := Match{DocumentID: 7, Key: "feed:5:product-017", Source: SourceSheet, Score: 0.93, Content: "AutoCut Pro ราคา 3,900 บาท"}
	cases := map[string]struct {
		item   Item
		match  []Match
		action Action
		reason string
	}{
		"private is refused": {Item{Label: LabelPrivate, Signals: Signals{Private: []string{"card number"}}, Source: SourceAI}, nil, ActionReject, "card number"},
		"irrelevant dropped": {Item{Label: LabelIrrelevant, Source: SourceUpload}, nil, ActionDrop, ""},
		"model failed":       {Item{Label: LabelReview, Source: SourceUpload}, nil, ActionQueue, "could not be sorted"},
		"new knowledge":      {Item{Piece: Piece{Content: "ติดตั้งบน Windows 10 ได้"}, Label: LabelKnowledge, Source: SourceUpload}, nil, ActionAdd, ""},
		"weak match is new":  {Item{Piece: Piece{Content: "ราคา 3,900 บาท"}, Label: LabelKnowledge, Source: SourceUpload}, []Match{{DocumentID: 7, Score: 0.6, Content: "x"}}, ActionAdd, ""},
		"same facts":         {Item{Piece: Piece{Content: "ราคา AutoCut Pro 3,900 บาท"}, Label: LabelKnowledge, Source: SourceUpload}, []Match{price}, ActionDuplicate, ""},
		"different price":    {Item{Piece: Piece{Content: "AutoCut Pro ราคา 2,900 บาท"}, Label: LabelKnowledge, Source: SourceAI}, []Match{price}, ActionQueue, "conflicts"},
		"same source key":    {Item{Piece: Piece{Key: "feed:5:product-017", Content: "AutoCut Pro ราคา 2,900 บาท"}, Label: LabelKnowledge, Source: SourceSheet}, []Match{price}, ActionUpdate, ""},
		"knowledge with payment link": {Item{Piece: Piece{Content: "ชำระที่ https://pay.example.com"}, Label: LabelKnowledge, Source: SourceSheet,
			Signals: Signals{Payment: []string{"payment link"}}}, nil, ActionQueue, "payment link"},
		"contact always queued": {Item{Label: LabelContact, Source: SourceOwner}, nil, ActionQueue, "contact"},
		"line id in knowledge from AI": {Item{Piece: Piece{Content: "แอดไลน์ @fake"}, Label: LabelKnowledge, Source: SourceAI,
			Signals: Signals{Contact: []string{"LINE"}}}, nil, ActionQueue, "LINE"},
		"line id in owner's sheet": {Item{Piece: Piece{Content: "แอดไลน์ @john"}, Label: LabelKnowledge, Source: SourceSheet,
			Signals: Signals{Contact: []string{"LINE"}}}, nil, ActionAdd, ""},
		"rules from owner upload": {Item{Label: LabelRules, Source: SourceUpload}, nil, ActionProfile, ""},
		"rules from an AI app":    {Item{Label: LabelRules, Source: SourceAI}, nil, ActionQueue, "AI app"},
		"tone from a web page":    {Item{Label: LabelTone, Source: SourceWeb}, nil, ActionQueue, "web page"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			d := Decide(c.item, c.match)

			// Assert
			if d.Action != c.action || !strings.Contains(d.Reason, c.reason) {
				t.Fatalf("Decide = %+v, want %s with reason containing %q", d, c.action, c.reason)
			}
		})
	}
}

func TestDecide_ConflictSuggestsTheMoreTrustedSource(t *testing.T) {
	// Arrange
	sheet := Match{DocumentID: 7, Source: SourceSheet, Score: 0.95, Content: "ราคา 3,900 บาท"}

	// Act
	fromAI := Decide(Item{Piece: Piece{Content: "ราคา 2,900 บาท"}, Label: LabelKnowledge, Source: SourceAI}, []Match{sheet})
	fromOwner := Decide(Item{Piece: Piece{Content: "ราคา 2,900 บาท"}, Label: LabelKnowledge, Source: SourceOwner}, []Match{sheet})

	// Assert
	if fromAI.Action != ActionQueue || fromAI.Suggest != SuggestKeep || fromAI.MatchID != 7 {
		t.Fatalf("from AI = %+v, want queue, keep the Sheet version", fromAI)
	}
	if fromOwner.Action != ActionQueue || fromOwner.Suggest != SuggestReplace {
		t.Fatalf("from owner = %+v, want queue, suggest replacing", fromOwner)
	}
}

func TestDecide_ProfileFieldNames(t *testing.T) {
	for label, field := range map[Label]string{LabelAbout: "about", LabelTone: "tone", LabelRules: "rules"} {
		// Act
		d := Decide(Item{Label: label, Source: SourceUpload}, nil)

		// Assert
		if d.Field != field {
			t.Errorf("%s → field %q, want %q", label, d.Field, field)
		}
	}
}
