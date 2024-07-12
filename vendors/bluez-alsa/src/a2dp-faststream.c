/*
 * BlueALSA - a2dp-faststream.c
 * Copyright (c) 2016-2024 Arkadiusz Bokowy
 *
 * This file is a part of bluez-alsa.
 *
 * This project is licensed under the terms of the MIT license.
 *
 */

#include "a2dp-faststream.h"

#include <errno.h>
#include <pthread.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include <sbc/sbc.h>

#include "a2dp.h"
#include "ba-config.h"
#include "ba-transport.h"
#include "ba-transport-pcm.h"
#include "codec-sbc.h"
#include "io.h"
#include "shared/a2dp-codecs.h"
#include "shared/defs.h"
#include "shared/ffb.h"
#include "shared/log.h"
#include "shared/rt.h"

static const struct a2dp_bit_mapping a2dp_faststream_samplings_music[] = {
	{ FASTSTREAM_SAMPLING_FREQ_MUSIC_44100, 44100 },
	{ FASTSTREAM_SAMPLING_FREQ_MUSIC_48000, 48000 },
	{ 0 }
};

static const struct a2dp_bit_mapping a2dp_faststream_samplings_voice[] = {
	{ FASTSTREAM_SAMPLING_FREQ_VOICE_16000, 16000 },
	{ 0 }
};

void *a2dp_faststream_enc_thread(struct ba_transport_pcm *t_pcm) {

	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);
	pthread_cleanup_push(PTHREAD_CLEANUP(ba_transport_pcm_thread_cleanup), t_pcm);

	struct ba_transport *t = t_pcm->t;
	struct io_poll io = { .timeout = -1 };

	/* determine encoder operation mode: music or voice */
	const bool is_voice = t->profile & BA_TRANSPORT_PROFILE_A2DP_SINK;

	sbc_t sbc;
	const a2dp_faststream_t *configuration = &t->a2dp.configuration.faststream;
	if ((errno = -sbc_init_a2dp_faststream(&sbc, 0, configuration,
					sizeof(*configuration), is_voice)) != 0) {
		error("Couldn't initialize FastStream SBC codec: %s", strerror(errno));
		goto fail_init;
	}

	ffb_t bt = { 0 };
	ffb_t pcm = { 0 };
	pthread_cleanup_push(PTHREAD_CLEANUP(ffb_free), &bt);
	pthread_cleanup_push(PTHREAD_CLEANUP(ffb_free), &pcm);
	pthread_cleanup_push(PTHREAD_CLEANUP(sbc_finish), &sbc);

	const unsigned int channels = t_pcm->channels;
	const size_t sbc_frame_len = sbc_get_frame_length(&sbc);
	const size_t sbc_frame_samples = sbc_get_codesize(&sbc) / sizeof(int16_t);

	if (ffb_init_int16_t(&pcm, sbc_frame_samples * 3) == -1 ||
			ffb_init_uint8_t(&bt, t->mtu_write) == -1) {
		error("Couldn't create data buffers: %s", strerror(ENOMEM));
		goto fail_ffb;
	}

	debug_transport_pcm_thread_loop(t_pcm, "START");
	for (ba_transport_pcm_state_set_running(t_pcm);;) {

		switch (io_poll_and_read_pcm(&io, t_pcm, &pcm)) {
		case -1:
			if (errno == ESTALE) {
				sbc_reinit_a2dp_faststream(&sbc, 0, configuration,
						sizeof(*configuration), is_voice);
				ffb_rewind(&pcm);
				continue;
			}
			error("PCM poll and read error: %s", strerror(errno));
			/* fall-through */
		case 0:
			ba_transport_stop_if_no_clients(t);
			continue;
		}

		const int16_t *input = pcm.data;
		size_t input_len = ffb_len_out(&pcm);
		size_t output_len = ffb_len_in(&bt);
		size_t pcm_frames = 0;
		size_t sbc_frames = 0;

		while (input_len >= sbc_frame_samples &&
				output_len >= sbc_frame_len &&
				sbc_frames < 3) {

			ssize_t len;
			ssize_t encoded;

			if ((len = sbc_encode(&sbc, input, input_len * sizeof(int16_t),
							bt.tail, output_len, &encoded)) < 0) {
				error("FastStream SBC encoding error: %s", sbc_strerror(len));
				break;
			}

			len = len / sizeof(int16_t);
			input += len;
			input_len -= len;
			ffb_seek(&bt, encoded);
			output_len -= encoded;
			pcm_frames += len / channels;
			sbc_frames += 1;

		}

		if (sbc_frames > 0) {

			ssize_t len = ffb_blen_out(&bt);
			if ((len = io_bt_write(t_pcm, bt.data, len)) <= 0) {
				if (len == -1)
					error("BT write error: %s", strerror(errno));
				goto fail;
			}

			/* make room for new FastStream frames */
			ffb_rewind(&bt);

			/* keep data transfer at a constant bit rate */
			asrsync_sync(&io.asrs, pcm_frames);

			/* update busy delay (encoding overhead) */
			t_pcm->delay = asrsync_get_busy_usec(&io.asrs) / 100;

			/* If the input buffer was not consumed (due to codesize limit), we
			 * have to append new data to the existing one. Since we do not use
			 * ring buffer, we will simply move unprocessed data to the front
			 * of our linear buffer. */
			ffb_shift(&pcm, pcm_frames * channels);

		}

	}

fail:
	debug_transport_pcm_thread_loop(t_pcm, "EXIT");
fail_ffb:
	pthread_cleanup_pop(1);
	pthread_cleanup_pop(1);
	pthread_cleanup_pop(1);
fail_init:
	pthread_cleanup_pop(1);
	return NULL;
}

__attribute__ ((weak))
void *a2dp_faststream_dec_thread(struct ba_transport_pcm *t_pcm) {

	pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);
	pthread_cleanup_push(PTHREAD_CLEANUP(ba_transport_pcm_thread_cleanup), t_pcm);

	struct ba_transport *t = t_pcm->t;
	struct io_poll io = { .timeout = -1 };

	/* determine decoder operation mode: music or voice */
	const bool is_voice = t->profile & BA_TRANSPORT_PROFILE_A2DP_SOURCE;

	sbc_t sbc;
	if ((errno = -sbc_init_a2dp_faststream(&sbc, 0, &t->a2dp.configuration.faststream,
					sizeof(t->a2dp.configuration.faststream), is_voice)) != 0) {
		error("Couldn't initialize FastStream SBC codec: %s", strerror(errno));
		goto fail_init;
	}

	const size_t sbc_frame_len = sbc_get_frame_length(&sbc);
	const size_t sbc_frame_samples = sbc_get_codesize(&sbc) / sizeof(int16_t);

	ffb_t bt = { 0 };
	ffb_t pcm = { 0 };
	pthread_cleanup_push(PTHREAD_CLEANUP(sbc_finish), &sbc);
	pthread_cleanup_push(PTHREAD_CLEANUP(ffb_free), &bt);
	pthread_cleanup_push(PTHREAD_CLEANUP(ffb_free), &pcm);

	if (ffb_init_int16_t(&pcm, sbc_frame_samples) == -1 ||
			ffb_init_uint8_t(&bt, t->mtu_read) == -1) {
		error("Couldn't create data buffers: %s", strerror(errno));
		goto fail_ffb;
	}

	debug_transport_pcm_thread_loop(t_pcm, "START");
	for (ba_transport_pcm_state_set_running(t_pcm);;) {

		ssize_t len;
		ffb_rewind(&bt);
		if ((len = io_poll_and_read_bt(&io, t_pcm, &bt)) <= 0) {
			if (len == -1)
				error("BT poll and read error: %s", strerror(errno));
			goto fail;
		}

		if (!ba_transport_pcm_is_active(t_pcm))
			continue;

		uint8_t *input = bt.data;
		size_t input_len = len;

		/* decode retrieved SBC frames */
		while (input_len >= sbc_frame_len) {

			size_t decoded;
			if ((len = sbc_decode(&sbc, input, input_len,
							pcm.data, ffb_blen_in(&pcm), &decoded)) < 0) {
				error("FastStream SBC decoding error: %s", sbc_strerror(len));
				break;
			}

			input += len;
			input_len -= len;

			const size_t samples = decoded / sizeof(int16_t);
			io_pcm_scale(t_pcm, pcm.data, samples);
			if (io_pcm_write(t_pcm, pcm.data, samples) == -1)
				error("PCM write error: %s", strerror(errno));

		}

	}

fail:
	debug_transport_pcm_thread_loop(t_pcm, "EXIT");
fail_ffb:
	pthread_cleanup_pop(1);
	pthread_cleanup_pop(1);
	pthread_cleanup_pop(1);
fail_init:
	pthread_cleanup_pop(1);
	return NULL;
}

static int a2dp_faststream_configuration_select(
		const struct a2dp_sep *sep,
		void *capabilities) {

	a2dp_faststream_t *caps = capabilities;
	const a2dp_faststream_t saved = *caps;

	/* narrow capabilities to values supported by BlueALSA */
	if (a2dp_filter_capabilities(sep, &sep->capabilities,
				caps, sizeof(*caps)) != 0)
		return -1;

	if ((caps->direction & (FASTSTREAM_DIRECTION_MUSIC | FASTSTREAM_DIRECTION_VOICE)) == 0) {
		error("FastStream: No supported directions: %#x", saved.direction);
		return errno = ENOTSUP, -1;
	}

	unsigned int sampling_freq_v = 0;
	if (caps->direction & FASTSTREAM_DIRECTION_VOICE &&
			a2dp_bit_mapping_foreach(a2dp_faststream_samplings_voice, caps->sampling_freq_voice,
				a2dp_foreach_get_best_sampling_freq, &sampling_freq_v) != -1)
		caps->sampling_freq_voice = sampling_freq_v;
	else {
		error("FastStream: No supported voice sampling frequencies: %#x", saved.sampling_freq_voice);
		return errno = ENOTSUP, -1;
	}

	unsigned int sampling_freq_m = 0;
	if (caps->direction & FASTSTREAM_DIRECTION_MUSIC &&
			a2dp_bit_mapping_foreach(a2dp_faststream_samplings_music, caps->sampling_freq_music,
				a2dp_foreach_get_best_sampling_freq, &sampling_freq_m) != -1)
		caps->sampling_freq_music = sampling_freq_m;
	else {
		error("FastStream: No supported music sampling frequencies: %#x", saved.sampling_freq_music);
		return errno = ENOTSUP, -1;
	}

	return 0;
}

static int a2dp_faststream_configuration_check(
		const struct a2dp_sep *sep,
		const void *configuration) {

	const a2dp_faststream_t *conf = configuration;
	a2dp_faststream_t conf_v = *conf;

	/* validate configuration against BlueALSA capabilities */
	if (a2dp_filter_capabilities(sep, &sep->capabilities,
				&conf_v, sizeof(conf_v)) != 0)
		return A2DP_CHECK_ERR_SIZE;

	if ((conf_v.direction & (FASTSTREAM_DIRECTION_MUSIC | FASTSTREAM_DIRECTION_VOICE)) == 0) {
		debug("FastStream: Invalid direction: %#x", conf->direction);
		return A2DP_CHECK_ERR_DIRECTIONS;
	}

	if (conf_v.direction & FASTSTREAM_DIRECTION_VOICE &&
			a2dp_bit_mapping_lookup(a2dp_faststream_samplings_voice, conf_v.sampling_freq_voice) == 0) {
		debug("FastStream: Invalid voice sampling frequency: %#x", conf->sampling_freq_voice);
		return A2DP_CHECK_ERR_SAMPLING_VOICE;
	}

	if (conf_v.direction & FASTSTREAM_DIRECTION_MUSIC &&
			a2dp_bit_mapping_lookup(a2dp_faststream_samplings_music, conf_v.sampling_freq_music) == 0) {
		debug("FastStream: Invalid music sampling frequency: %#x", conf->sampling_freq_music);
		return A2DP_CHECK_ERR_SAMPLING_MUSIC;
	}

	return A2DP_CHECK_OK;
}

static int a2dp_faststream_transport_init(struct ba_transport *t) {

	if (t->a2dp.configuration.faststream.direction & FASTSTREAM_DIRECTION_MUSIC) {

		unsigned int sampling;
		if ((sampling = a2dp_bit_mapping_lookup(a2dp_faststream_samplings_music,
						t->a2dp.configuration.faststream.sampling_freq_music)) == 0)
			return -1;

		t->a2dp.pcm.format = BA_TRANSPORT_PCM_FORMAT_S16_2LE;
		t->a2dp.pcm.sampling = sampling;
		t->a2dp.pcm.channels = 2;

	}

	if (t->a2dp.configuration.faststream.direction & FASTSTREAM_DIRECTION_VOICE) {

		unsigned int sampling;
		if ((sampling = a2dp_bit_mapping_lookup(a2dp_faststream_samplings_voice,
						t->a2dp.configuration.faststream.sampling_freq_voice)) == 0)
			return -1;

		t->a2dp.pcm_bc.format = BA_TRANSPORT_PCM_FORMAT_S16_2LE;
		t->a2dp.pcm_bc.sampling = sampling;
		t->a2dp.pcm_bc.channels = 1;

	}

	return 0;
}

static int a2dp_faststream_source_init(struct a2dp_sep *sep) {
	if (config.a2dp.force_mono)
		warn("FastStream: Mono channel mode not supported");
	if (config.a2dp.force_44100)
		sep->capabilities.faststream.sampling_freq_music = FASTSTREAM_SAMPLING_FREQ_MUSIC_44100;
	return 0;
}

static int a2dp_faststream_source_transport_start(struct ba_transport *t) {

	struct ba_transport_pcm *pcm = &t->a2dp.pcm;
	struct ba_transport_pcm *pcm_bc = &t->a2dp.pcm_bc;
	int rv = 0;

	if (t->a2dp.configuration.faststream.direction & FASTSTREAM_DIRECTION_MUSIC)
		rv |= ba_transport_pcm_start(pcm, a2dp_faststream_enc_thread, "ba-a2dp-fs-m");
	if (t->a2dp.configuration.faststream.direction & FASTSTREAM_DIRECTION_VOICE)
		rv |= ba_transport_pcm_start(pcm_bc, a2dp_faststream_dec_thread, "ba-a2dp-fs-v");

	return rv;
}

struct a2dp_sep a2dp_faststream_source = {
	.type = A2DP_SOURCE,
	.codec_id = A2DP_CODEC_VENDOR_ID(FASTSTREAM_VENDOR_ID, FASTSTREAM_CODEC_ID),
	.synopsis = "A2DP Source (FastStream)",
	.capabilities.faststream = {
		.info = A2DP_VENDOR_INFO_INIT(FASTSTREAM_VENDOR_ID, FASTSTREAM_CODEC_ID),
		.direction = FASTSTREAM_DIRECTION_MUSIC | FASTSTREAM_DIRECTION_VOICE,
		.sampling_freq_music =
			FASTSTREAM_SAMPLING_FREQ_MUSIC_44100 |
			FASTSTREAM_SAMPLING_FREQ_MUSIC_48000,
		.sampling_freq_voice =
			FASTSTREAM_SAMPLING_FREQ_VOICE_16000,
	},
	.capabilities_size = sizeof(a2dp_faststream_t),
	.init = a2dp_faststream_source_init,
	.configuration_select = a2dp_faststream_configuration_select,
	.configuration_check = a2dp_faststream_configuration_check,
	.transport_init = a2dp_faststream_transport_init,
	.transport_start = a2dp_faststream_source_transport_start,
};

static int a2dp_faststream_sink_transport_start(struct ba_transport *t) {

	struct ba_transport_pcm *pcm = &t->a2dp.pcm;
	struct ba_transport_pcm *pcm_bc = &t->a2dp.pcm_bc;
	int rv = 0;

	if (t->a2dp.configuration.faststream.direction & FASTSTREAM_DIRECTION_MUSIC)
		rv |= ba_transport_pcm_start(pcm, a2dp_faststream_dec_thread, "ba-a2dp-fs-m");
	if (t->a2dp.configuration.faststream.direction & FASTSTREAM_DIRECTION_VOICE)
		rv |= ba_transport_pcm_start(pcm_bc, a2dp_faststream_enc_thread, "ba-a2dp-fs-v");

	return rv;
}

struct a2dp_sep a2dp_faststream_sink = {
	.type = A2DP_SINK,
	.codec_id = A2DP_CODEC_VENDOR_ID(FASTSTREAM_VENDOR_ID, FASTSTREAM_CODEC_ID),
	.synopsis = "A2DP Sink (FastStream)",
	.capabilities.faststream = {
		.info = A2DP_VENDOR_INFO_INIT(FASTSTREAM_VENDOR_ID, FASTSTREAM_CODEC_ID),
		.direction = FASTSTREAM_DIRECTION_MUSIC | FASTSTREAM_DIRECTION_VOICE,
		.sampling_freq_music =
			FASTSTREAM_SAMPLING_FREQ_MUSIC_44100 |
			FASTSTREAM_SAMPLING_FREQ_MUSIC_48000,
		.sampling_freq_voice =
			FASTSTREAM_SAMPLING_FREQ_VOICE_16000,
	},
	.capabilities_size = sizeof(a2dp_faststream_t),
	.configuration_select = a2dp_faststream_configuration_select,
	.configuration_check = a2dp_faststream_configuration_check,
	.transport_init = a2dp_faststream_transport_init,
	.transport_start = a2dp_faststream_sink_transport_start,
};
