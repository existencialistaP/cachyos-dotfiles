#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["sherpa-onnx", "numpy"]
# ///
"""Transcreve PCM s16le 16 kHz mono (raw) com o parakeet que o Orca usa.

O modelo vem do Orca (~/.config/orca/speech-models), então não há download
próprio: o ditado do quickshell reusa o mesmo STT local.
"""

import argparse
import os
import sys

import numpy as np
import sherpa_onnx

DEFAULT_MODEL = "~/.config/orca/speech-models/parakeet-tdt-0.6b-v3-int8"
MODEL_FILES = {
    "encoder": "encoder.int8.onnx",
    "decoder": "decoder.int8.onnx",
    "joiner": "joiner.int8.onnx",
    "tokens": "tokens.txt",
}
SAMPLE_RATE = 16000


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw", required=True, help="PCM s16le 16 kHz mono")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="diretório do modelo")
    parser.add_argument("--threads", type=int, default=4)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    model_dir = os.path.expanduser(args.model)
    paths = {key: os.path.join(model_dir, name) for key, name in MODEL_FILES.items()}
    missing = [path for path in paths.values() if not os.path.isfile(path)]
    if missing:
        print("modelo incompleto: " + ", ".join(missing), file=sys.stderr)
        return 2

    samples = np.fromfile(args.raw, dtype=np.int16).astype(np.float32) / 32768.0
    if samples.size == 0:
        return 0

    recognizer = sherpa_onnx.OfflineRecognizer.from_transducer(
        encoder=paths["encoder"],
        decoder=paths["decoder"],
        joiner=paths["joiner"],
        tokens=paths["tokens"],
        num_threads=args.threads,
        sample_rate=SAMPLE_RATE,
        feature_dim=80,
        decoding_method="greedy_search",
        model_type="nemo_transducer",
    )

    stream = recognizer.create_stream()
    stream.accept_waveform(SAMPLE_RATE, samples)
    recognizer.decode_stream(stream)
    print(stream.result.text.strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
