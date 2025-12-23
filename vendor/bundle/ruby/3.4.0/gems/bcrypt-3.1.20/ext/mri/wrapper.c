/*
 * Written by Solar Designer <solar at openwall.com> in 2000-2014.
 * No copyright is claimed, and the software is hereby placed in the public
 * domain.  In case this attempt to disclaim copyright and place the software
 * in the public domain is deemed null and void, then the software is
 * Copyright (c) 2000-2014 Solar Designer and it is hereby released to the
 * general public under the following terms:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted.
 *
 * There's ABSOLUTELY NO WARRANTY, express or implied.
 *
 * See crypt_blowfish.c for more information.
 */

#include <stdlib.h>
#include <string.h>

/* Redefine strdup to ruby_strdup in case string.h doesn't export it. */
#include <ruby/util.h>

#include <errno.h>
#ifndef __set_errno
#define __set_errno(val) errno = (val)
#endif

#ifdef TEST
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sys/time.h>
#include <sys/times.h>
#ifdef TEST_THREADS
#include <pthread.h>
#endif
#endif

#define CRYPT_OUTPUT_SIZE		(7 + 22 + 31 + 1)
#define CRYPT_GENSALT_OUTPUT_SIZE	(7 + 22 + 1)

#if defined(__GLIBC__) && defined(_LIBC)
#define __SKIP_GNU
#endif
#include "ow-crypt.h"

#include "crypt_blowfish.h"
#include "crypt_gensalt.h"

#if defined(__GLIBC__) && defined(_LIBC)
/* crypt.h from glibc-crypt-2.1 will define struct crypt_data for us */
#include "crypt.h"
extern char *__md5_crypt_r(const char *key, const char *salt,
	char *buffer, int buflen);
/* crypt-entry.c needs to be patched to define __des_crypt_r rather than
 * __crypt_r, and not define crypt_r and crypt at all */
extern char *__des_crypt_r(const char *key, const char *salt,
	struct crypt_data *data);
extern struct crypt_data _ufc_foobar;
#endif

static int _crypt_data_alloc(void **data, int *size, int need)
{
	void *updated;

	if (*data && *size >= need) return 0;

	updated = realloc(*data, need);

	if (!updated) {
#ifndef __GLIBC__
		/* realloc(3) on glibc sets errno, so we don't need to bother */
		__set_errno(ENOMEM);
#endif
		return -1;
	}

#if defined(__GLIBC__) && defined(_LIBC)
	if (need >= sizeof(struct crypt_data))
		((struct crypt_data *)updated)->initialized = 0;
#endif

	*data = updated;
	*size = need;

	return 0;
}

static char *_crypt_retval_magic(char *retval, const char *setting,
	char *output, int size)
{
	if (retval)
		return retval;

	if (_crypt_output_magic(setting, output, size))
		return NULL; /* shouldn't happen */

	return output;
}

#if defined(__GLIBC__) && defined(_LIBC)
/*
 * Applications may re-use the same instance of struct crypt_data without
 * resetting the initialized field in order to let crypt_r() skip some of
 * its initialization code.  Thus, it is important that our multiple hashing
 * algorithms either don't conflict with each other in their use of the
 * data area or reset the initialized field themselves whenever required.
 * Currently, the hashing algorithms simply have no conflicts: the first
 * field of struct crypt_data is the 128-byte large DES key schedule which
 * __des_crypt_r() calculates each time it is called while the two other
 * hashing algorithms use less than 128 bytes of the data area.
 */

char *__crypt_rn(__const char *key, __const char *setting,
	void *data, int size)
{
	if (setting[0] == '$' && setting[1] == '2')
		return _crypt_blowfish_rn(key, setting, (char *)data, size);
	if (setting[0] == '$' && setting[1] == '1')
		return __md5_crypt_r(key, setting, (char *)data, size);
	if (setting[0] == '$' || setting[0] == '_') {
		__set_errno(EINVAL);
		return NULL;
	}
	if (size >= sizeof(struct crypt_data))
		return __des_crypt_r(key, setting, (struct crypt_data *)data);
	__set_errno(ERANGE);
	return NULL;
}

char *__crypt_ra(__const char *key, __const char *setting,
	void **data, int *size)
{
	if (setting[0] == '$' && setting[1] == '2') {
		if (_crypt_data_alloc(data, size, CRYPT_OUTPUT_SIZE))
			return NULL;
		return _crypt_blowfish_rn(key, setting, (char *)*data, *size);
	}
	if (setting[0] == '$' && setting[1] == '1') {
		if (_crypt_data_alloc(data, size, CRYPT_OUTPUT_SIZE))
			return NULL;
		return __md5_crypt_r(key, setting, (char *)*data, *size);
	}
	if (setting[0] == '$' || setting[0] == '_') {
		__set_errno(EINVAL);
		return NULL;
	}
	if (_crypt_data_alloc(data, size, sizeof(struct crypt_data)))
		return NULL;
	return __des_crypt_r(key, setting, (struct crypt_data *)*data);
}

char *__crypt_r(__const char *key, __const char *setting,
	struct crypt_data *data)
{
	return _crypt_retval_magic(
		__crypt_rn(key, setting, data, sizeof(*data)),
		setting, (char *)data, sizeof(*data));
}

char *__crypt(__const char *key, __const char *setting)
{
	return _crypt_retval_magic(
		__crypt_rn(key, setting, &_ufc_foobar, sizeof(_ufc_foobar)),
		setting, (char *)&_ufc_foobar, sizeof(_ufc_foobar));
}
#else
char *crypt_rn(const char *key, const char *setting, void *data, int size)
{
	return _crypt_blowfish_rn(key, setting, (char *)data, size);
}

char *crypt_ra(const char *key, const char *setting,
	void **data, int *size)
{
	if (_crypt_data_alloc(data, size, CRYPT_OUTPUT_SIZE))
		return NULL;
	return _crypt_blowfish_rn(key, setting, (char *)*data, *size);
}

char *crypt_r(const char *key, const char *setting, struct crypt_data *data)
{
	return _crypt_retval_magic(
		crypt_rn(key, setting, data, CRYPT_OUTPUT_SIZE),
		setting, (char *)data, CRYPT_OUTPUT_SIZE);
}

char *crypt(const char *key, const char *setting)
{
	static char output[CRYPT_OUTPUT_SIZE];

	return _crypt_retval_magic(
		crypt_rn(key, setting, output, sizeof(output)),
		setting, output, sizeof(output));
}

#define __crypt_gensalt_rn crypt_gensalt_rn
#define __crypt_gensalt_ra crypt_gensalt_ra
#define __crypt_gensalt crypt_gensalt
#endif

char *__crypt_gensalt_rn(const char *prefix, unsigned long count,
	const char *input, int size, char *output, int output_size)
{
	char *(*use)(const char *_prefix, unsigned long _count,
		const char *_input, int _size,
		char *_output, int _output_size);

	/* This may be supported on some platforms in the future */
	if (!input) {
		__set_errno(EINVAL);
		return NULL;
	}

	if (!strncmp(prefix, "$2a$", 4) || !strncmp(prefix, "$2b$", 4) ||
	    !strncmp(prefix, "$2y$", 4))
		use = _crypt_gensalt_blowfish_rn;
	else
	if (!strncmp(prefix, "$1$", 3))
		use = _crypt_gensalt_md5_rn;
	else
	if (prefix[0] == '_')
		use = _crypt_gensalt_extended_rn;
	else
	if (!prefix[0] ||
	    (prefix[0] && prefix[1] &&
	    memchr(_crypt_itoa64, prefix[0], 64) &&
	    memchr(_crypt_itoa64, prefix[1], 64)))
		use = _crypt_gensalt_traditional_rn;
	else {
		__set_errno(EINVAL);
		return NULL;
	}

	return use(prefix, count, input, size, output, output_size);
}

char *__crypt_gensalt_ra(const char *prefix, unsigned long count,
	const char *input, int size)
{
	char output[CRYPT_GENSALT_OUTPUT_SIZE];
	char *retval;

	retval = __crypt_gensalt_rn(prefix, count,
		input, size, output, sizeof(output));

	if (retval) {
		retval = strdup(retval);
#ifndef __GLIBC__
		/* strdup(3) on glibc sets errno, so we don't need to bother */
		if (!retval)
			__set_errno(ENOMEM);
#endif
	}

	return retval;
}

char *__crypt_gensalt(const char *prefix, unsigned long count,
	const char *input, int size)
{
	static char output[CRYPT_GENSALT_OUTPUT_SIZE];

	return __crypt_gensalt_rn(prefix, count,
		input, size, output, sizeof(output));
}

#if defined(__GLIBC__) && defined(_LIBC)
weak_alias(__crypt_rn, crypt_rn)
weak_alias(__crypt_ra, crypt_ra)
weak_alias(__crypt_r, crypt_r)
weak_alias(__crypt, crypt)
weak_alias(__crypt_gensalt_rn, crypt_gensalt_rn)
weak_alias(__crypt_gensalt_ra, crypt_gensalt_ra)
weak_alias(__crypt_gensalt, crypt_gensalt)
weak_alias(crypt, fcrypt)
#endif

#ifdef TEST
static const char *tests[][3] = {
	{"$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW",
		"U*U"},
	{"$2a$05$CCCCCCCCCCCCCCCCCCCCC.VGOzA784oUp/Z0DY336zx7pLYAy0lwK",
		"U*U*"},
	{"$2a$05$XXXXXXXXXXXXXXXXXXXXXOAcXxm9kjPGEMsLznoKqmqw7tc8WCx4a",
		"U*U*U"},
	{"$2a$05$abcdefghijklmnopqrstuu5s2v8.iXieOjg/.AySBTTZIIVFJeBui",
		"0123456789abcdefghijklmnopqrstuvwxyz"
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		"chars after 72 are ignored"},
	{"$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e",
		"\xa3"},
	{"$2x$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e",
		"\xff\xff\xa3"},
	{"$2y$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e",
		"\xff\xff\xa3"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.nqd1wy.pTMdcvrRWxyiGL2eMz.2a85.",
		"\xff\xff\xa3"},
	{"$2b$05$/OK.fbVrR/bpIqNJ5ianF.CE5elHaaO4EbggVDjb8P19RukzXSM3e",
		"\xff\xff\xa3"},
	{"$2y$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq",
		"\xa3"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq",
		"\xa3"},
	{"$2b$05$/OK.fbVrR/bpIqNJ5ianF.Sa7shbm4.OzKpvFnX1pQLmQW96oUlCq",
		"\xa3"},
	{"$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi",
		"1\xa3" "345"},
	{"$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi",
		"\xff\xa3" "345"},
	{"$2x$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi",
		"\xff\xa3" "34" "\xff\xff\xff\xa3" "345"},
	{"$2y$05$/OK.fbVrR/bpIqNJ5ianF.o./n25XVfn6oAPaUvHe.Csk4zRfsYPi",
		"\xff\xa3" "34" "\xff\xff\xff\xa3" "345"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.ZC1JEJ8Z4gPfpe1JOr/oyPXTWl9EFd.",
		"\xff\xa3" "34" "\xff\xff\xff\xa3" "345"},
	{"$2y$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e",
		"\xff\xa3" "345"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.nRht2l/HRhr6zmCp9vYUvvsqynflf9e",
		"\xff\xa3" "345"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS",
		"\xa3" "ab"},
	{"$2x$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS",
		"\xa3" "ab"},
	{"$2y$05$/OK.fbVrR/bpIqNJ5ianF.6IflQkJytoRVc1yuaNtHfiuq.FRlSIS",
		"\xa3" "ab"},
	{"$2x$05$6bNw2HLQYeqHYyBfLMsv/OiwqTymGIGzFsA4hOTWebfehXHNprcAS",
		"\xd1\x91"},
	{"$2x$05$6bNw2HLQYeqHYyBfLMsv/O9LIGgn8OMzuDoHfof8AQimSGfcSWxnS",
		"\xd0\xc1\xd2\xcf\xcc\xd8"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.swQOIzjOiJ9GHEPuhEkvqrUyvWhEMx6",
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
		"\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
		"chars after 72 are ignored as usual"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.R9xrDjiycxMbQE2bp.vgqlYpW5wx2yy",
		"\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55"
		"\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55"
		"\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55"
		"\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55"
		"\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55"
		"\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55\xaa\x55"},
	{"$2a$05$/OK.fbVrR/bpIqNJ5ianF.9tQZzcJfm3uj2NvJ/n5xkhpqLrMpWCe",
		"\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff"
		"\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff"
		"\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff"
		"\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff"
		"\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff"
		"\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff\x55\xaa\xff"},
	{"$2a$05$CCCCCCCCCCCCCCCCCCCCC.7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy",
		""},
	{"*0", "", "$2a$03$CCCCCCCCCCCCCCCCCCCCC."},
	{"*0", "", "$2a$32$CCCCCCCCCCCCCCCCCCCCC."},
	{"*0", "", "$2c$05$CCCCCCCCCCCCCCCCCCCCC."},
	{"*0", "", "$2z$05$CCCCCCCCCCCCCCCCCCCCC."},
	{"*0", "", "$2`$05$CCCCCCCCCCCCCCCCCCCCC."},
	{"*0", "", "$2{$05$CCCCCCCCCCCCCCCCCCCCC."},
	{"*1", "", "*0"},
	{NULL}
};

#define which				tests[0]

static volatile sig_atomic_t running;

static void handle_timer(int signum)
{
	(void) signum;
	running = 0;
}

static void *run(void *arg)
{
	unsigned long count = 0;
	int i = 0;
	void *data = NULL;
	int size = 0x12345678;

	do {
		const char *hash = tests[i][0];
		const char *key = tests[i][1];
		const char *setting = tests[i][2];

		if (!tests[++i][0])
			i = 0;

		if (setting && strlen(hash) < 30) /* not for benchmark */
			continue;

		if (strcmp(crypt_ra(key, hash, &data, &size), hash)) {
			printf("%d: FAILED (crypt_ra/%d/%lu)\n",
				(int)((char *)arg - (char *)0), i, count);
			free(data);
			return NULL;
		}
		count++;
	} while (running);

	free(data);
	return count + (char *)0;
}

int main(void)
{
	struct itimerval it;
	struct tms buf;
	clock_t clk_tck, start_real, start_virtual, end_real, end_virtual;
	unsigned long count;
	void *data;
	int size;
	char *setting1, *setting2;
	int i;
#ifdef TEST_THREADS
	pthread_t t[TEST_THREADS];
	void *t_retval;
#endif

	data = NULL;
	size = 0x12345678;

	for (i = 0; tests[i][0]; i++) {
		const char *hash = tests[i][0];
		const char *key = tests[i][1];
		const char *setting = tests[i][2];
		const char *p;
		int ok = !setting || strlen(hash) >= 30;
		int o_size;
		char s_buf[30], o_buf[61];
		if (!setting) {
			memcpy(s_buf, hash, sizeof(s_buf) - 1);
			s_buf[sizeof(s_buf) - 1] = 0;
			setting = s_buf;
		}

		__set_errno(0);
		p = crypt(key, setting);
		if ((!ok && !errno) || strcmp(p, hash)) {
			printf("FAILED (crypt/%d)\n", i);
			return 1;
		}

		if (ok && strcmp(crypt(key, hash), hash)) {
			printf("FAILED (crypt/%d)\n", i);
			return 1;
		}

		for (o_size = -1; o_size <= (int)sizeof(o_buf); o_size++) {
			int ok_n = ok && o_size == (int)sizeof(o_buf);
			const char *x = "abc";
			strcpy(o_buf, x);
			if (o_size >= 3) {
				x = "*0";
				if (setting[0] == '*' && setting[1] == '0')
					x = "*1";
			}
			__set_errno(0);
			p = crypt_rn(key, setting, o_buf, o_size);
			if ((ok_n && (!p || strcmp(p, hash))) ||
			    (!ok_n && (!errno || p || strcmp(o_buf, x)))) {
				printf("FAILED (crypt_rn/%d)\n", i);
				return 1;
			}
		}

		__set_errno(0);
		p = crypt_ra(key, setting, &data, &size);
		if ((ok && (!p || strcmp(p, hash))) ||
		    (!ok && (!errno || p || strcmp((char *)data, hash)))) {
			printf("FAILED (crypt_ra/%d)\n", i);
			return 1;
		}
	}

	setting1 = crypt_gensalt(which[0], 12, data, size);
	if (!setting1 || strncmp(setting1, "$2a$12$", 7)) {
		puts("FAILED (crypt_gensalt)\n");
		return 1;
	}

	setting2 = crypt_gensalt_ra(setting1, 12, data, size);
	if (strcmp(setting1, setting2)) {
		puts("FAILED (crypt_gensalt_ra/1)\n");
		return 1;
	}

	(*(char *)data)++;
	setting1 = crypt_gensalt_ra(setting2, 12, data, size);
	if (!strcmp(setting1, setting2)) {
		puts("FAILED (crypt_gensalt_ra/2)\n");
		return 1;
	}

	free(setting1);
	free(setting2);
	free(data);

#if defined(_SC_CLK_TCK) || !defined(CLK_TCK)
	clk_tck = sysconf(_SC_CLK_TCK);
#else
	clk_tck = CLK_TCK;
#endif

	running = 1;
	signal(SIGALRM, handle_timer);

	memset(&it, 0, sizeof(it));
	it.it_value.tv_sec = 5;
	setitimer(ITIMER_REAL, &it, NULL);

	start_real = times(&buf);
	start_virtual = buf.tms_utime + buf.tms_stime;

	count = (char *)run((char *)0) - (char *)0;

	end_real = times(&buf);
	end_virtual = buf.tms_utime + buf.tms_stime;
	if (end_virtual == start_virtual) end_virtual++;

	printf("%.1f c/s real, %.1f c/s virtual\n",
		(float)count * clk_tck / (end_real - start_real),
		(float)count * clk_tck / (end_virtual - start_virtual));

#ifdef TEST_THREADS
	running = 1;
	it.it_value.tv_sec = 60;
	setitimer(ITIMER_REAL, &it, NULL);
	start_real = times(&buf);

	for (i = 0; i < TEST_THREADS; i++)
	if (pthread_create(&t[i], NULL, run, i + (char *)0)) {
		perror("pthread_create");
		return 1;
	}

	for (i = 0; i < TEST_THREADS; i++) {
		if (pthread_join(t[i], &t_retval)) {
			perror("pthread_join");
			continue;
		}
		if (!t_retval) continue;
		count = (char *)t_retval - (char *)0;
		end_real = times(&buf);
		printf("%d: %.1f c/s real\n", i,
			(float)count * clk_tck / (end_real - start_real));
	}
#endif

	return 0;
}
#endif
