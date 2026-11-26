#!/usr/bin/env python3
"""Build a static game wordlist from a CC BY 4.0 frequency list.

Run once before compiling Phoenix, or let Dockerfile run this step.
The resulting text contains uppercase A-Z / Ñ words that fit the 11x11 board.
It is a permissive *game lexicon*, not an official Spanish-language authority.
"""
import argparse
import re
import unicodedata
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_URL = 'https://raw.githubusercontent.com/doozan/spanish_data/master/es_merged_50k.txt'
DEFAULT_OUTPUT = ROOT / 'priv/dictionary/es_lexicafe_extended.txt'
BASE = ROOT / 'priv/dictionary/es_mx_demo.txt'
VALID = re.compile(r'^[A-ZÑ]{2,11}$')


def normalize(word):
    # Keep Ñ independent, remove accents from vowels including Ü.
    word = word.strip().upper().replace('Ñ', '\ue000')
    decomposed = unicodedata.normalize('NFD', word)
    return ''.join(ch for ch in decomposed if unicodedata.category(ch) != 'Mn').replace('\ue000', 'Ñ')


def build(content, demo_text):
    words = set()
    for line in content.splitlines():
        # Original format: palabra<tab>frecuencia (one entry per row)
        parts = line.strip().split()
        if parts:
            word = normalize(parts[0])
            if VALID.fullmatch(word):
                words.add(word)
    for line in demo_text.splitlines():
        if line.strip().startswith('#'):
            continue
        for word in line.split():
            word = normalize(word)
            if VALID.fullmatch(word):
                words.add(word)
    return sorted(words)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-url', default=DEFAULT_URL)
    parser.add_argument('--source-file', type=Path, help='Use downloaded content instead of Internet')
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if args.source_file:
        raw = args.source_file.read_text(encoding='utf-8')
    else:
        request = urllib.request.Request(args.source_url, headers={'User-Agent': 'Lexicafe-MVP/1.2 (+open-source-game)'})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                raw = response.read().decode('utf-8-sig')
        except Exception as exc:
            raise SystemExit(f'Error al descargar el diccionario ({exc}). Reintenta con Internet o usa --source-file.') from exc
    words = build(raw, BASE.read_text(encoding='utf-8'))
    if not args.source_file and len(words) < 10000:
        raise SystemExit(f'La descarga no contiene suficientes términos válidos: {len(words)}.')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text('\n'.join(words) + '\n', encoding='utf-8')
    print(f'Lexicafé: {len(words):,} palabras incorporadas a {args.output}')


if __name__ == '__main__':
    main()
