package knowledge

import (
	"bytes"
	"context"
	"strings"
	"testing"
)

func TestEvaluate_ScoresAnswerableAndUnanswerable(t *testing.T) {
	// Arrange
	index := map[string][]Hit{
		"hours":    {{Title: "Opening hours", Score: 0.8}},
		"shipping": {{Title: "Returns", Score: 0.5}, {Title: "Shipping policy", Score: 0.45}},
		"weather":  nil,
		"missing":  {{Title: "Returns", Score: 0.4}},
		"politics": {{Title: "Opening hours", Score: 0.31}},
	}
	retrieve := func(_ context.Context, _, _ int64, q ...string) ([]Hit, error) { return index[q[0]], nil }
	cases := []EvalCase{
		{Question: "hours", Expect: "opening"},
		{Question: "shipping", Expect: "Shipping"},
		{Question: "missing", Expect: "Warranty"},
		{Question: "weather"},
		{Question: "politics"},
	}

	// Act
	rep := Evaluate(context.Background(), retrieve, cases)
	var out bytes.Buffer
	rep.Write(&out)

	// Assert
	if rep.Answerable != 3 || rep.Found != 2 || rep.Unanswerable != 2 || rep.Empty != 1 {
		t.Fatalf("report = %+v", rep)
	}
	if rep.MRR < 0.49 || rep.MRR > 0.51 { // (1 + 1/2 + 0) / 3
		t.Errorf("MRR = %v", rep.MRR)
	}
	if rep.Results[1].Rank != 2 || rep.Results[2].Pass || rep.Results[4].Pass {
		t.Errorf("results = %+v", rep.Results)
	}
	if !strings.Contains(out.String(), "2/3 found (67%)") || !strings.Contains(out.String(), "1/2 returned nothing") {
		t.Errorf("output:\n%s", out.String())
	}
}
