/**********************************************************************

  stackprof.c - Sampling call-stack frame profiler for MRI.

  vim: noexpandtab shiftwidth=4 tabstop=8 softtabstop=4

**********************************************************************/

#include <ruby/ruby.h>
#include <ruby/version.h>
#include <ruby/debug.h>
#include <ruby/st.h>
#include <ruby/io.h>
#include <ruby/intern.h>
#include <ruby/vm.h>
#include <signal.h>
#include <sys/time.h>
#include <time.h>
#include <pthread.h>

#define BUF_SIZE 2048
#define MICROSECONDS_IN_SECOND 1000000
#define NANOSECONDS_IN_SECOND 1000000000

#define FAKE_FRAME_GC    INT2FIX(0)
#define FAKE_FRAME_MARK  INT2FIX(1)
#define FAKE_FRAME_SWEEP INT2FIX(2)

static const char *fake_frame_cstrs[] = {
	"(garbage collection)",
	"(marking)",
	"(sweeping)",
};

static int stackprof_use_postponed_job = 1;
static int ruby_vm_running = 0;

#define TOTAL_FAKE_FRAMES (sizeof(fake_frame_cstrs) / sizeof(char *))

#ifdef _POSIX_MONOTONIC_CLOCK
  #define timestamp_t timespec
  typedef struct timestamp_t timestamp_t;

  static void capture_timestamp(timestamp_t *ts) {
      clock_gettime(CLOCK_MONOTONIC, ts);
  }

  static int64_t delta_usec(timestamp_t *start, timestamp_t *end) {
      int64_t result = MICROSECONDS_IN_SECOND * (end->tv_sec - start->tv_sec);
      if (end->tv_nsec < start->tv_nsec) {
	  result -= MICROSECONDS_IN_SECOND;
	  result += (NANOSECONDS_IN_SECOND + end->tv_nsec - start->tv_nsec) / 1000;
      } else {
	  result += (end->tv_nsec - start->tv_nsec) / 1000;
      }
      return result;
  }

  static uint64_t timestamp_usec(timestamp_t *ts) {
      return (MICROSECONDS_IN_SECOND * ts->tv_sec) + (ts->tv_nsec / 1000);
  }
#else
  #define timestamp_t timeval
  typedef struct timestamp_t timestamp_t;

  static void capture_timestamp(timestamp_t *ts) {
      gettimeofday(ts, NULL);
  }

  static int64_t delta_usec(timestamp_t *start, timestamp_t *end) {
      struct timeval diff;
      timersub(end, start, &diff);
      return (MICROSECONDS_IN_SECOND * diff.tv_sec) + diff.tv_usec;
  }

  static uint64_t timestamp_usec(timestamp_t *ts) {
      return (MICROSECONDS_IN_SECOND * ts.tv_sec) + diff.tv_usec
  }
#endif

typedef struct {
    size_t total_samples;
    size_t caller_samples;
    size_t seen_at_sample_number;
    st_table *edges;
    st_table *lines;
} frame_data_t;

typedef struct {
    uint64_t timestamp_usec;
    int64_t delta_usec;
} sample_time_t;

static struct {
    int running;
    int raw;
    int aggregate;

    VALUE mode;
    VALUE interval;
    VALUE out;
    VALUE metadata;
    int ignore_gc;

    VALUE *raw_samples;
    size_t raw_samples_len;
    size_t raw_samples_capa;
    size_t raw_sample_index;

    struct timestamp_t last_sample_at;
    sample_time_t *raw_sample_times;
    size_t raw_sample_times_len;
    size_t raw_sample_times_capa;

    size_t overall_signals;
    size_t overall_samples;
    size_t during_gc;
    size_t unrecorded_gc_samples;
    size_t unrecorded_gc_marking_samples;
    size_t unrecorded_gc_sweeping_samples;
    st_table *frames;

    VALUE fake_frame_names[TOTAL_FAKE_FRAMES];
    VALUE empty_string;

    int buffer_count;
    sample_time_t buffer_time;
    VALUE frames_buffer[BUF_SIZE];
    int lines_buffer[BUF_SIZE];

    pthread_t target_thread;
} _stackprof;

static VALUE sym_object, sym_wall, sym_cpu, sym_custom, sym_name, sym_file, sym_line;
static VALUE sym_samples, sym_total_samples, sym_missed_samples, sym_edges, sym_lines;
static VALUE sym_version, sym_mode, sym_interval, sym_raw, sym_metadata, sym_frames, sym_ignore_gc, sym_out;
static VALUE sym_aggregate, sym_raw_sample_timestamps, sym_raw_timestamp_deltas, sym_state, sym_marking, sym_sweeping;
static VALUE sym_gc_samples, objtracer;
static VALUE gc_hook;
static VALUE rb_mStackProf;

static void stackprof_newobj_handler(VALUE, void*);
static void stackprof_signal_handler(int sig, siginfo_t* sinfo, void* ucontext);

static VALUE
stackprof_start(int argc, VALUE *argv, VALUE self)
{
    struct sigaction sa;
    struct itimerval timer;
    VALUE opts = Qnil, mode = Qnil, interval = Qnil, metadata = rb_hash_new(), out = Qfalse;
    int ignore_gc = 0;
    int raw = 0, aggregate = 1;
    VALUE metadata_val;

    if (_stackprof.running)
	return Qfalse;

    rb_scan_args(argc, argv, "0:", &opts);

    if (RTEST(opts)) {
	mode = rb_hash_aref(opts, sym_mode);
	interval = rb_hash_aref(opts, sym_interval);
	out = rb_hash_aref(opts, sym_out);
	if (RTEST(rb_hash_aref(opts, sym_ignore_gc))) {
	    ignore_gc = 1;
	}

	metadata_val = rb_hash_aref(opts, sym_metadata);
	if (RTEST(metadata_val)) {
	    if (!RB_TYPE_P(metadata_val, T_HASH))
		rb_raise(rb_eArgError, "metadata should be a hash");

	    metadata = metadata_val;
	}

	if (RTEST(rb_hash_aref(opts, sym_raw)))
	    raw = 1;
	if (rb_hash_lookup2(opts, sym_aggregate, Qundef) == Qfalse)
	    aggregate = 0;
    }
    if (!RTEST(mode)) mode = sym_wall;

    if (!NIL_P(interval) && (NUM2INT(interval) < 1 || NUM2INT(interval) >= MICROSECONDS_IN_SECOND)) {
        rb_raise(rb_eArgError, "interval is a number of microseconds between 1 and 1 million");
    }

    if (!_stackprof.frames) {
	_stackprof.frames = st_init_numtable();
	_stackprof.overall_signals = 0;
	_stackprof.overall_samples = 0;
	_stackprof.during_gc = 0;
    }

    if (mode == sym_object) {
	if (!RTEST(interval)) interval = INT2FIX(1);

	objtracer = rb_tracepoint_new(Qnil, RUBY_INTERNAL_EVENT_NEWOBJ, stackprof_newobj_handler, 0);
	rb_tracepoint_enable(objtracer);
    } else if (mode == sym_wall || mode == sym_cpu) {
	if (!RTEST(interval)) interval = INT2FIX(1000);

	sa.sa_sigaction = stackprof_signal_handler;
	sa.sa_flags = SA_RESTART | SA_SIGINFO;
	sigemptyset(&sa.sa_mask);
	sigaction(mode == sym_wall ? SIGALRM : SIGPROF, &sa, NULL);

	timer.it_interval.tv_sec = 0;
	timer.it_interval.tv_usec = NUM2LONG(interval);
	timer.it_value = timer.it_interval;
	setitimer(mode == sym_wall ? ITIMER_REAL : ITIMER_PROF, &timer, 0);
    } else if (mode == sym_custom) {
	/* sampled manually */
	interval = Qnil;
    } else {
	rb_raise(rb_eArgError, "unknown profiler mode");
    }

    _stackprof.running = 1;
    _stackprof.raw = raw;
    _stackprof.aggregate = aggregate;
    _stackprof.mode = mode;
    _stackprof.interval = interval;
    _stackprof.ignore_gc = ignore_gc;
    _stackprof.metadata = metadata;
    _stackprof.out = out;
    _stackprof.target_thread = pthread_self();

    if (raw) {
	capture_timestamp(&_stackprof.last_sample_at);
    }

    return Qtrue;
}

static VALUE
stackprof_stop(VALUE self)
{
    struct sigaction sa;
    struct itimerval timer;

    if (!_stackprof.running)
	return Qfalse;
    _stackprof.running = 0;

    if (_stackprof.mode == sym_object) {
	rb_tracepoint_disable(objtracer);
    } else if (_stackprof.mode == sym_wall || _stackprof.mode == sym_cpu) {
	memset(&timer, 0, sizeof(timer));
	setitimer(_stackprof.mode == sym_wall ? ITIMER_REAL : ITIMER_PROF, &timer, 0);

	sa.sa_handler = SIG_IGN;
	sa.sa_flags = SA_RESTART;
	sigemptyset(&sa.sa_mask);
	sigaction(_stackprof.mode == sym_wall ? SIGALRM : SIGPROF, &sa, NULL);
    } else if (_stackprof.mode == sym_custom) {
	/* sampled manually */
    } else {
	rb_raise(rb_eArgError, "unknown profiler mode");
    }

    return Qtrue;
}

#if SIZEOF_VOIDP == SIZEOF_LONG
#  define PTR2NUM(x) (LONG2NUM((long)(x)))
#else
#  define PTR2NUM(x) (LL2NUM((LONG_LONG)(x)))
#endif

static int
frame_edges_i(st_data_t key, st_data_t val, st_data_t arg)
{
    VALUE edges = (VALUE)arg;

    intptr_t weight = (intptr_t)val;
    rb_hash_aset(edges, PTR2NUM(key), INT2FIX(weight));
    return ST_CONTINUE;
}

static int
frame_lines_i(st_data_t key, st_data_t val, st_data_t arg)
{
    VALUE lines = (VALUE)arg;

    size_t weight = (size_t)val;
    size_t total = weight & (~(size_t)0 << (8*SIZEOF_SIZE_T/2));
    weight -= total;
    total = total >> (8*SIZEOF_SIZE_T/2);
    rb_hash_aset(lines, INT2FIX(key), rb_ary_new3(2, ULONG2NUM(total), ULONG2NUM(weight)));
    return ST_CONTINUE;
}

static int
frame_i(st_data_t key, st_data_t val, st_data_t arg)
{
    VALUE frame = (VALUE)key;
    frame_data_t *frame_data = (frame_data_t *)val;
    VALUE results = (VALUE)arg;
    VALUE details = rb_hash_new();
    VALUE name, file, edges, lines;
    VALUE line;

    rb_hash_aset(results, PTR2NUM(frame), details);

    if (FIXNUM_P(frame)) {
	name = _stackprof.fake_frame_names[FIX2INT(frame)];
	file = _stackprof.empty_string;
	line = INT2FIX(0);
    } else {
	name = rb_profile_frame_full_label(frame);

	file = rb_profile_frame_absolute_path(frame);
	if (NIL_P(file))
	    file = rb_profile_frame_path(frame);
	line = rb_profile_frame_first_lineno(frame);
    }

    rb_hash_aset(details, sym_name, name);
    rb_hash_aset(details, sym_file, file);
    if (line != INT2FIX(0)) {
	rb_hash_aset(details, sym_line, line);
    }

    rb_hash_aset(details, sym_total_samples, SIZET2NUM(frame_data->total_samples));
    rb_hash_aset(details, sym_samples, SIZET2NUM(frame_data->caller_samples));

    if (frame_data->edges) {
        edges = rb_hash_new();
        rb_hash_aset(details, sym_edges, edges);
        st_foreach(frame_data->edges, frame_edges_i, (st_data_t)edges);
        st_free_table(frame_data->edges);
        frame_data->edges = NULL;
    }

    if (frame_data->lines) {
	lines = rb_hash_new();
	rb_hash_aset(details, sym_lines, lines);
	st_foreach(frame_data->lines, frame_lines_i, (st_data_t)lines);
	st_free_table(frame_data->lines);
	frame_data->lines = NULL;
    }

    xfree(frame_data);
    return ST_DELETE;
}

static VALUE
stackprof_results(int argc, VALUE *argv, VALUE self)
{
    VALUE results, frames;

    if (!_stackprof.frames || _stackprof.running)
	return Qnil;

    results = rb_hash_new();
    rb_hash_aset(results, sym_version, DBL2NUM(1.2));
    rb_hash_aset(results, sym_mode, _stackprof.mode);
    rb_hash_aset(results, sym_interval, _stackprof.interval);
    rb_hash_aset(results, sym_samples, SIZET2NUM(_stackprof.overall_samples));
    rb_hash_aset(results, sym_gc_samples, SIZET2NUM(_stackprof.during_gc));
    rb_hash_aset(results, sym_missed_samples, SIZET2NUM(_stackprof.overall_signals - _stackprof.overall_samples));
    rb_hash_aset(results, sym_metadata, _stackprof.metadata);

    _stackprof.metadata = Qnil;

    frames = rb_hash_new();
    rb_hash_aset(results, sym_frames, frames);
    st_foreach(_stackprof.frames, frame_i, (st_data_t)frames);

    st_free_table(_stackprof.frames);
    _stackprof.frames = NULL;

    if (_stackprof.raw && _stackprof.raw_samples_len) {
	size_t len, n, o;
	VALUE raw_sample_timestamps, raw_timestamp_deltas;
	VALUE raw_samples = rb_ary_new_capa(_stackprof.raw_samples_len);

	for (n = 0; n < _stackprof.raw_samples_len; n++) {
	    len = (size_t)_stackprof.raw_samples[n];
	    rb_ary_push(raw_samples, SIZET2NUM(len));

	    for (o = 0, n++; o < len; n++, o++)
		rb_ary_push(raw_samples, PTR2NUM(_stackprof.raw_samples[n]));
	    rb_ary_push(raw_samples, SIZET2NUM((size_t)_stackprof.raw_samples[n]));
	}

	free(_stackprof.raw_samples);
	_stackprof.raw_samples = NULL;
	_stackprof.raw_samples_len = 0;
	_stackprof.raw_samples_capa = 0;
	_stackprof.raw_sample_index = 0;

	rb_hash_aset(results, sym_raw, raw_samples);

	raw_sample_timestamps = rb_ary_new_capa(_stackprof.raw_sample_times_len);
	raw_timestamp_deltas = rb_ary_new_capa(_stackprof.raw_sample_times_len);

	for (n = 0; n < _stackprof.raw_sample_times_len; n++) {
	    rb_ary_push(raw_sample_timestamps, ULL2NUM(_stackprof.raw_sample_times[n].timestamp_usec));
	    rb_ary_push(raw_timestamp_deltas, LL2NUM(_stackprof.raw_sample_times[n].delta_usec));
	}

	free(_stackprof.raw_sample_times);
	_stackprof.raw_sample_times = NULL;
	_stackprof.raw_sample_times_len = 0;
	_stackprof.raw_sample_times_capa = 0;

	rb_hash_aset(results, sym_raw_sample_timestamps, raw_sample_timestamps);
	rb_hash_aset(results, sym_raw_timestamp_deltas, raw_timestamp_deltas);

	_stackprof.raw = 0;
    }

    if (argc == 1)
	_stackprof.out = argv[0];

    if (RTEST(_stackprof.out)) {
	VALUE file;
	if (rb_respond_to(_stackprof.out, rb_intern("to_io"))) {
	    file = rb_io_check_io(_stackprof.out);
	} else {
	    file = rb_file_open_str(_stackprof.out, "w");
	}

	rb_marshal_dump(results, file);
	rb_io_flush(file);
	_stackprof.out = Qnil;
	return file;
    } else {
	return results;
    }
}

static VALUE
stackprof_run(int argc, VALUE *argv, VALUE self)
{
    rb_need_block();
    stackprof_start(argc, argv, self);
    rb_ensure(rb_yield, Qundef, stackprof_stop, self);
    return stackprof_results(0, 0, self);
}

static VALUE
stackprof_running_p(VALUE self)
{
    return _stackprof.running ? Qtrue : Qfalse;
}

static inline frame_data_t *
sample_for(VALUE frame)
{
    st_data_t key = (st_data_t)frame, val = 0;
    frame_data_t *frame_data;

    if (st_lookup(_stackprof.frames, key, &val)) {
        frame_data = (frame_data_t *)val;
    } else {
        frame_data = ALLOC_N(frame_data_t, 1);
        MEMZERO(frame_data, frame_data_t, 1);
        val = (st_data_t)frame_data;
        st_insert(_stackprof.frames, key, val);
    }

    return frame_data;
}

static int
numtable_increment_callback(st_data_t *key, st_data_t *value, st_data_t arg, int existing)
{
    size_t *weight = (size_t *)value;
    size_t increment = (size_t)arg;

    if (existing)
	(*weight) += increment;
    else
	*weight = increment;

    return ST_CONTINUE;
}

void
st_numtable_increment(st_table *table, st_data_t key, size_t increment)
{
    st_update(table, key, numtable_increment_callback, (st_data_t)increment);
}

void
stackprof_record_sample_for_stack(int num, uint64_t sample_timestamp, int64_t timestamp_delta)
{
    int i, n;
    VALUE prev_frame = Qnil;

    _stackprof.overall_samples++;

    if (_stackprof.raw && num > 0) {
	int found = 0;

	/* If there's no sample buffer allocated, then allocate one.  The buffer
	 * format is the number of frames (num), then the list of frames (from
	 * `_stackprof.raw_samples`), followed by the number of times this
	 * particular stack has been seen in a row.  Each "new" stack is added
	 * to the end of the buffer, but if the previous stack is the same as
	 * the current stack, the counter will be incremented. */
	if (!_stackprof.raw_samples) {
	    _stackprof.raw_samples_capa = num * 100;
	    _stackprof.raw_samples = malloc(sizeof(VALUE) * _stackprof.raw_samples_capa);
	}

	/* If we can't fit all the samples in the buffer, double the buffer size. */
	while (_stackprof.raw_samples_capa <= _stackprof.raw_samples_len + (num + 2)) {
	    _stackprof.raw_samples_capa *= 2;
	    _stackprof.raw_samples = realloc(_stackprof.raw_samples, sizeof(VALUE) * _stackprof.raw_samples_capa);
	}

	/* If we've seen this stack before in the last sample, then increment the "seen" count. */
	if (_stackprof.raw_samples_len > 0 && _stackprof.raw_samples[_stackprof.raw_sample_index] == (VALUE)num) {
	    /* The number of samples could have been the same, but the stack
	     * might be different, so we need to check the stack here.  Stacks
	     * in the raw buffer are stored in the opposite direction of stacks
	     * in the frames buffer that came from Ruby. */
	    for (i = num-1, n = 0; i >= 0; i--, n++) {
		VALUE frame = _stackprof.frames_buffer[i];
		if (_stackprof.raw_samples[_stackprof.raw_sample_index + 1 + n] != frame)
		    break;
	    }
	    if (i == -1) {
		_stackprof.raw_samples[_stackprof.raw_samples_len-1] += 1;
		found = 1;
	    }
	}

	/* If we haven't seen the stack, then add it to the buffer along with
	 * the length of the stack and a 1 for the "seen" count */
	if (!found) {
	    /* Bump the `raw_sample_index` up so that the next iteration can
	     * find the previously recorded stack size. */
	    _stackprof.raw_sample_index = _stackprof.raw_samples_len;
	    _stackprof.raw_samples[_stackprof.raw_samples_len++] = (VALUE)num;
	    for (i = num-1; i >= 0; i--) {
		VALUE frame = _stackprof.frames_buffer[i];
		_stackprof.raw_samples[_stackprof.raw_samples_len++] = frame;
	    }
	    _stackprof.raw_samples[_stackprof.raw_samples_len++] = (VALUE)1;
	}

	/* If there's no timestamp delta buffer, allocate one */
	if (!_stackprof.raw_sample_times) {
	    _stackprof.raw_sample_times_capa = 100;
	    _stackprof.raw_sample_times = malloc(sizeof(sample_time_t) * _stackprof.raw_sample_times_capa);
	    _stackprof.raw_sample_times_len = 0;
	}

	/* Double the buffer size if it's too small */
	while (_stackprof.raw_sample_times_capa <= _stackprof.raw_sample_times_len + 1) {
	    _stackprof.raw_sample_times_capa *= 2;
	    _stackprof.raw_sample_times = realloc(_stackprof.raw_sample_times, sizeof(sample_time_t) * _stackprof.raw_sample_times_capa);
	}

	/* Store the time delta (which is the amount of microseconds between samples). */
	_stackprof.raw_sample_times[_stackprof.raw_sample_times_len++] = (sample_time_t) {
	    .timestamp_usec = sample_timestamp,
	    .delta_usec = timestamp_delta,
        };
    }

    for (i = 0; i < num; i++) {
	int line = _stackprof.lines_buffer[i];
	VALUE frame = _stackprof.frames_buffer[i];
	frame_data_t *frame_data = sample_for(frame);

	if (frame_data->seen_at_sample_number != _stackprof.overall_samples) {
	    frame_data->total_samples++;
	}
	frame_data->seen_at_sample_number = _stackprof.overall_samples;

	if (i == 0) {
	    frame_data->caller_samples++;
	} else if (_stackprof.aggregate) {
	    if (!frame_data->edges)
		frame_data->edges = st_init_numtable();
	    st_numtable_increment(frame_data->edges, (st_data_t)prev_frame, 1);
	}

	if (_stackprof.aggregate && line > 0) {
	    size_t half = (size_t)1<<(8*SIZEOF_SIZE_T/2);
	    size_t increment = i == 0 ? half + 1 : half;
	    if (!frame_data->lines)
		frame_data->lines = st_init_numtable();
	    st_numtable_increment(frame_data->lines, (st_data_t)line, increment);
	}

	prev_frame = frame;
    }

    if (_stackprof.raw) {
	capture_timestamp(&_stackprof.last_sample_at);
    }
}

// buffer the current profile frames
// This must be async-signal-safe
// Returns immediately if another set of frames are already in the buffer
void
stackprof_buffer_sample(void)
{
    uint64_t start_timestamp = 0;
    int64_t timestamp_delta = 0;
    int num;

    if (_stackprof.buffer_count > 0) {
	// Another sample is already pending
	return;
    }

    if (_stackprof.raw) {
	struct timestamp_t t;
	capture_timestamp(&t);
	start_timestamp = timestamp_usec(&t);
	timestamp_delta = delta_usec(&_stackprof.last_sample_at, &t);
    }

    num = rb_profile_frames(0, sizeof(_stackprof.frames_buffer) / sizeof(VALUE), _stackprof.frames_buffer, _stackprof.lines_buffer);

    _stackprof.buffer_count = num;
    _stackprof.buffer_time.timestamp_usec = start_timestamp;
    _stackprof.buffer_time.delta_usec = timestamp_delta;
}

void
stackprof_record_gc_samples(void)
{
    int64_t delta_to_first_unrecorded_gc_sample = 0;
    uint64_t start_timestamp = 0;
    size_t i;
    if (_stackprof.raw) {
	struct timestamp_t t;
	capture_timestamp(&t);
	start_timestamp = timestamp_usec(&t);

	// We don't know when the GC samples were actually marked, so let's
	// assume that they were marked at a perfectly regular interval.
	delta_to_first_unrecorded_gc_sample = delta_usec(&_stackprof.last_sample_at, &t) - (_stackprof.unrecorded_gc_samples - 1) * NUM2LONG(_stackprof.interval);
	if (delta_to_first_unrecorded_gc_sample < 0) {
	    delta_to_first_unrecorded_gc_sample = 0;
	}
    }

    for (i = 0; i < _stackprof.unrecorded_gc_samples; i++) {
	int64_t timestamp_delta = i == 0 ? delta_to_first_unrecorded_gc_sample : NUM2LONG(_stackprof.interval);

      if (_stackprof.unrecorded_gc_marking_samples) {
        _stackprof.frames_buffer[0] = FAKE_FRAME_MARK;
        _stackprof.lines_buffer[0] = 0;
        _stackprof.frames_buffer[1] = FAKE_FRAME_GC;
        _stackprof.lines_buffer[1] = 0;
        _stackprof.unrecorded_gc_marking_samples--;

        stackprof_record_sample_for_stack(2, start_timestamp, timestamp_delta);
      } else if (_stackprof.unrecorded_gc_sweeping_samples) {
        _stackprof.frames_buffer[0] = FAKE_FRAME_SWEEP;
        _stackprof.lines_buffer[0] = 0;
        _stackprof.frames_buffer[1] = FAKE_FRAME_GC;
        _stackprof.lines_buffer[1] = 0;

        _stackprof.unrecorded_gc_sweeping_samples--;

        stackprof_record_sample_for_stack(2, start_timestamp, timestamp_delta);
      } else {
        _stackprof.frames_buffer[0] = FAKE_FRAME_GC;
        _stackprof.lines_buffer[0] = 0;
        stackprof_record_sample_for_stack(1, start_timestamp, timestamp_delta);
      }
    }
    _stackprof.during_gc += _stackprof.unrecorded_gc_samples;
    _stackprof.unrecorded_gc_samples = 0;
    _stackprof.unrecorded_gc_marking_samples = 0;
    _stackprof.unrecorded_gc_sweeping_samples = 0;
}

// record the sample previously buffered by stackprof_buffer_sample
static void
stackprof_record_buffer(void)
{
    stackprof_record_sample_for_stack(_stackprof.buffer_count, _stackprof.buffer_time.timestamp_usec, _stackprof.buffer_time.delta_usec);

    // reset the buffer
    _stackprof.buffer_count = 0;
}

static void
stackprof_sample_and_record(void)
{
    stackprof_buffer_sample();
    stackprof_record_buffer();
}

static void
stackprof_job_record_gc(void *data)
{
    if (!_stackprof.running) return;

    stackprof_record_gc_samples();
}

static void
stackprof_job_sample_and_record(void *data)
{
    if (!_stackprof.running) return;

    stackprof_sample_and_record();
}

static void
stackprof_job_record_buffer(void *data)
{
    if (!_stackprof.running) return;

    stackprof_record_buffer();
}

static void
stackprof_signal_handler(int sig, siginfo_t *sinfo, void *ucontext)
{
    static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

    _stackprof.overall_signals++;

    if (!_stackprof.running) return;

    // There's a possibility that the signal handler is invoked *after* the Ruby
    // VM has been shut down (e.g. after ruby_cleanup(0)). In this case, things
    // that rely on global VM state (e.g. rb_during_gc) will segfault.
    if (!ruby_vm_running) return;

    if (_stackprof.mode == sym_wall) {
        // In "wall" mode, the SIGALRM signal will arrive at an arbitrary thread.
        // In order to provide more useful results, especially under threaded web
        // servers, we want to forward this signal to the original thread
        // StackProf was started from.
        // According to POSIX.1-2008 TC1 pthread_kill and pthread_self should be
        // async-signal-safe.
        if (pthread_self() != _stackprof.target_thread) {
            pthread_kill(_stackprof.target_thread, sig);
            return;
        }
    } else {
        if (!ruby_native_thread_p()) return;
    }

    if (pthread_mutex_trylock(&lock)) return;

    if (!_stackprof.ignore_gc && rb_during_gc()) {
	VALUE mode = rb_gc_latest_gc_info(sym_state);
	if (mode == sym_marking) {
	    _stackprof.unrecorded_gc_marking_samples++;
	} else if (mode == sym_sweeping) {
	    _stackprof.unrecorded_gc_sweeping_samples++;
	}
	_stackprof.unrecorded_gc_samples++;
	rb_postponed_job_register_one(0, stackprof_job_record_gc, (void*)0);
    } else {
        if (stackprof_use_postponed_job) {
            rb_postponed_job_register_one(0, stackprof_job_sample_and_record, (void*)0);
        } else {
            // Buffer a sample immediately, if an existing sample exists this will
            // return immediately
            stackprof_buffer_sample();
            // Enqueue a job to record the sample
            rb_postponed_job_register_one(0, stackprof_job_record_buffer, (void*)0);
        }
    }
    pthread_mutex_unlock(&lock);
}

static void
stackprof_newobj_handler(VALUE tpval, void *data)
{
    _stackprof.overall_signals++;
    if (RTEST(_stackprof.interval) && _stackprof.overall_signals % NUM2LONG(_stackprof.interval))
	return;
    stackprof_sample_and_record();
}

static VALUE
stackprof_sample(VALUE self)
{
    if (!_stackprof.running)
	return Qfalse;

    _stackprof.overall_signals++;
    stackprof_sample_and_record();
    return Qtrue;
}

static int
frame_mark_i(st_data_t key, st_data_t val, st_data_t arg)
{
    VALUE frame = (VALUE)key;
    rb_gc_mark(frame);
    return ST_CONTINUE;
}

static void
stackprof_gc_mark(void *data)
{
    if (RTEST(_stackprof.metadata))
	rb_gc_mark(_stackprof.metadata);

    if (RTEST(_stackprof.out))
	rb_gc_mark(_stackprof.out);

    if (_stackprof.frames)
	st_foreach(_stackprof.frames, frame_mark_i, 0);

    for (int i = 0; i < _stackprof.buffer_count; i++) {
        rb_gc_mark(_stackprof.frames_buffer[i]);
    }
}

static void
stackprof_atfork_prepare(void)
{
    struct itimerval timer;
    if (_stackprof.running) {
	if (_stackprof.mode == sym_wall || _stackprof.mode == sym_cpu) {
	    memset(&timer, 0, sizeof(timer));
	    setitimer(_stackprof.mode == sym_wall ? ITIMER_REAL : ITIMER_PROF, &timer, 0);
	}
    }
}

static void
stackprof_atfork_parent(void)
{
    struct itimerval timer;
    if (_stackprof.running) {
	if (_stackprof.mode == sym_wall || _stackprof.mode == sym_cpu) {
	    timer.it_interval.tv_sec = 0;
	    timer.it_interval.tv_usec = NUM2LONG(_stackprof.interval);
	    timer.it_value = timer.it_interval;
	    setitimer(_stackprof.mode == sym_wall ? ITIMER_REAL : ITIMER_PROF, &timer, 0);
	}
    }
}

static void
stackprof_atfork_child(void)
{
    stackprof_stop(rb_mStackProf);
}

static VALUE
stackprof_use_postponed_job_l(VALUE self)
{
    stackprof_use_postponed_job = 1;
    return Qnil;
}

static void
stackprof_at_exit(ruby_vm_t* vm)
{
    ruby_vm_running = 0;
}

void
Init_stackprof(void)
{
    size_t i;
   /*
    * As of Ruby 3.0, it should be safe to read stack frames at any time, unless YJIT is enabled
    * See https://github.com/ruby/ruby/commit/0e276dc458f94d9d79a0f7c7669bde84abe80f21
    */
    stackprof_use_postponed_job = RUBY_API_VERSION_MAJOR < 3;

    ruby_vm_running = 1;
    ruby_vm_at_exit(stackprof_at_exit);

#define S(name) sym_##name = ID2SYM(rb_intern(#name));
    S(object);
    S(custom);
    S(wall);
    S(cpu);
    S(name);
    S(file);
    S(line);
    S(total_samples);
    S(gc_samples);
    S(missed_samples);
    S(samples);
    S(edges);
    S(lines);
    S(version);
    S(mode);
    S(interval);
    S(raw);
    S(raw_sample_timestamps);
    S(raw_timestamp_deltas);
    S(out);
    S(metadata);
    S(ignore_gc);
    S(frames);
    S(aggregate);
    S(state);
    S(marking);
    S(sweeping);
#undef S

    /* Need to run this to warm the symbol table before we call this during GC */
    rb_gc_latest_gc_info(sym_state);

    gc_hook = Data_Wrap_Struct(rb_cObject, stackprof_gc_mark, NULL, &_stackprof);
    rb_global_variable(&gc_hook);

    _stackprof.raw_samples = NULL;
    _stackprof.raw_samples_len = 0;
    _stackprof.raw_samples_capa = 0;
    _stackprof.raw_sample_index = 0;

    _stackprof.raw_sample_times = NULL;
    _stackprof.raw_sample_times_len = 0;
    _stackprof.raw_sample_times_capa = 0;

    _stackprof.empty_string = rb_str_new_cstr("");
    rb_global_variable(&_stackprof.empty_string);

    for (i = 0; i < TOTAL_FAKE_FRAMES; i++) {
	    _stackprof.fake_frame_names[i] = rb_str_new_cstr(fake_frame_cstrs[i]);
	    rb_global_variable(&_stackprof.fake_frame_names[i]);
    }

    rb_mStackProf = rb_define_module("StackProf");
    rb_define_singleton_method(rb_mStackProf, "running?", stackprof_running_p, 0);
    rb_define_singleton_method(rb_mStackProf, "run", stackprof_run, -1);
    rb_define_singleton_method(rb_mStackProf, "start", stackprof_start, -1);
    rb_define_singleton_method(rb_mStackProf, "stop", stackprof_stop, 0);
    rb_define_singleton_method(rb_mStackProf, "results", stackprof_results, -1);
    rb_define_singleton_method(rb_mStackProf, "sample", stackprof_sample, 0);
    rb_define_singleton_method(rb_mStackProf, "use_postponed_job!", stackprof_use_postponed_job_l, 0);

    pthread_atfork(stackprof_atfork_prepare, stackprof_atfork_parent, stackprof_atfork_child);
}
