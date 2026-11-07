package pdftext

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"os/exec"
	"runtime"
	"runtime/debug"
	"time"
)

// The PDF parser runs in a child process: a crafted file can make it recurse
// until the stack overflows (fatal in Go, not recoverable), loop forever, or
// inflate a compressed stream into gigabytes. In a child, any of those ends
// only that process: the parent kills it on timeout, and the child exits
// itself when its heap passes MaxChildMemory. One PDF is read at a time.

const childEnv = "AISVC_PDFTEXT_CHILD"

// MaxChildMemory is the child's heap ceiling.
const MaxChildMemory = 512 << 20

// IsChild reports whether this process was started to read one PDF.
func IsChild() bool { return os.Getenv(childEnv) == "1" }

// RunChild reads a PDF from in and writes the result as JSON to out. Call it
// first thing in main when IsChild; it returns the exit code.
func RunChild(in io.Reader, out io.Writer) int {
	debug.SetMemoryLimit(MaxChildMemory / 2)
	go watchMemory()
	b, err := io.ReadAll(io.LimitReader(in, MaxBytes+1))
	if err != nil {
		return 2
	}
	res, err := extract(b)
	reply := childReply{Text: res.Text, Pages: res.Pages, Truncated: res.Truncated}
	if err != nil {
		reply.Err = errCode(err)
	}
	if json.NewEncoder(out).Encode(reply) != nil {
		return 2
	}
	return 0
}

// watchMemory ends the child when the parser allocates without bound.
func watchMemory() {
	var m runtime.MemStats
	for {
		runtime.ReadMemStats(&m)
		if m.HeapAlloc > MaxChildMemory {
			os.Exit(3)
		}
		time.Sleep(20 * time.Millisecond)
	}
}

type childReply struct {
	Text      string `json:"text"`
	Pages     int    `json:"pages"`
	Truncated bool   `json:"truncated"`
	Err       string `json:"err,omitempty"`
}

var codes = map[string]error{
	"too_large": ErrTooLarge, "no_text": ErrNoText, "encrypted": ErrEncrypted,
	"unreadable": ErrUnreadable, "timeout": ErrTimeout,
}

func errCode(err error) string {
	for code, e := range codes {
		if errors.Is(err, e) {
			return code
		}
	}
	return "unreadable"
}

// ErrBusy means another PDF is being read right now.
var ErrBusy = errors.New("another PDF is being read right now; try again in a minute")

// one PDF at a time: each child may use a core and MaxChildMemory.
var slot = make(chan struct{}, 1)

// executable is the program started as the child (os.Executable; the test
// binary in tests).
var executable = os.Executable

// runChild starts the child and waits for it, at most Timeout.
func runChild(ctx context.Context, b []byte) (Result, error) {
	select {
	case slot <- struct{}{}:
		defer func() { <-slot }()
	default:
		return Result{}, ErrBusy
	}
	exe, err := executable()
	if err != nil {
		return Result{}, ErrUnreadable
	}
	ctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), Timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, exe)
	cmd.Env = append(childEnviron(), childEnv+"=1")
	cmd.Stdin = bytes.NewReader(b)
	var out limitedBuffer
	out.max = 8 * MaxRunes // JSON-escaped text fits well within this
	cmd.Stdout, cmd.Stderr = &out, io.Discard
	cmd.WaitDelay = time.Second
	runErr := cmd.Run()
	if ctx.Err() != nil {
		return Result{}, ErrTimeout
	}
	if runErr != nil || out.over {
		return Result{}, ErrUnreadable // crashed, ran out of memory, or wrote too much
	}
	var reply childReply
	if err := json.Unmarshal(out.Bytes(), &reply); err != nil {
		return Result{}, ErrUnreadable
	}
	if reply.Err != "" {
		if e, ok := codes[reply.Err]; ok {
			return Result{}, e
		}
		return Result{}, ErrUnreadable
	}
	return Result{Text: reply.Text, Pages: reply.Pages, Truncated: reply.Truncated}, nil
}

// childEnviron passes no secrets to the child: only what Go needs to run.
func childEnviron() []string {
	var env []string
	for _, k := range []string{"PATH", "HOME", "TMPDIR", "GOCOVERDIR"} {
		if v, ok := os.LookupEnv(k); ok {
			env = append(env, k+"="+v)
		}
	}
	return env
}

type limitedBuffer struct {
	bytes.Buffer
	max  int
	over bool
}

func (l *limitedBuffer) Write(p []byte) (int, error) {
	if l.Len()+len(p) > l.max {
		l.over = true
		return 0, errors.New("output too large")
	}
	return l.Buffer.Write(p)
}
