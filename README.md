# cdn-bench

> **Benchmark 9 global CDNs from your machine** — Cloudflare vs jsDelivr vs Bunny vs Fastly vs CloudFront vs Akamai vs Google CDN vs Azure vs UNPKG. Pick the one that's actually fastest *for your users*.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/shell-bash-1f425f.svg)](#)
[![CDNs: 9](https://img.shields.io/badge/CDNs-9-blue.svg)](#)
[![Stars](https://img.shields.io/github/stars/fafsfafaf/cdn-bench?style=social)](https://github.com/fafsfafaf/cdn-bench/stargazers)

```bash
curl -fsSL https://raw.githubusercontent.com/fafsfafaf/cdn-bench/master/cdn-bench.sh | bash
```

## Demo

Recorded with [asciinema](https://asciinema.org/). View it locally:

```bash
# install asciinema if needed: pip install asciinema
asciinema play demo.cast
```

Or upload to asciinema.org for an embeddable badge:

```bash
asciinema auth      # one-time, opens browser
asciinema upload demo.cast
```

## Why

Picking a CDN by marketing slides is silly. The right answer is "whichever has the lowest latency from where your users actually are." `cdn-bench` measures **DNS / TCP-connect / TLS-handshake / total time** from your machine to 9 major CDN edges, in 15 seconds.

## Output

```
cdn-bench v1.0.0 · 9 CDNs · 3 rounds each

  CDN           DNS       CONNECT    TLS       TOTAL (avg)
  ──────────────────────────────────────────────────────────
  Cloudflare    2ms       6ms        14ms      28ms
  jsDelivr      3ms       7ms        15ms      32ms
  Bunny         3ms       12ms       28ms      55ms
  Fastly        2ms       8ms        18ms      36ms
  Akamai        4ms       11ms       24ms      48ms
  CloudFront    5ms       12ms       27ms      52ms
  GoogleCDN     2ms       6ms        15ms      30ms
  MS Azure      6ms       14ms       30ms      62ms
  UNPKG         4ms       9ms        20ms      40ms

  🏆 fastest CDN from your location: Cloudflare (28ms total)
```

## What it actually measures

For each CDN, fetches a small static asset 3 times and reports the average of `curl`'s built-in timing breakdown:

- `time_namelookup` — DNS resolution
- `time_connect` — TCP handshake
- `time_appconnect` — TLS handshake
- `time_total` — full round-trip (handshakes + first byte + body)

Lower is better in all columns. The TOTAL column is color-coded: green <50ms, cyan <150ms, yellow <400ms, magenta ≥400ms.

## Use cases

- Picking a JS/CSS library CDN (cdnjs/jsdelivr/unpkg/google)
- Deciding between Cloudflare, Fastly, Bunny for your own site
- Sanity-checking after a CDN migration
- Showing your boss why "use cloudfront" might be wrong for an EU audience

## Limitations

- Measures from **one location** (yours). For real coverage, run from multiple regions (e.g. cheap VPS in 5 cities).
- Different CDNs serve different test files (size differs slightly), so "TOTAL" includes body-download time. Compare DNS/CONNECT/TLS for purest network comparison.

## License

MIT
