# Phonics Annotation Specification

> **Version:** 1.0
> **Audience:** Claude (annotation generator), human reviewers, developers
> **Status:** Authoritative — ALL phonics annotations MUST conform to this spec
>
> This is the **single source of truth** for every phonics annotation in the
> CamelliaQuill vocabulary system. Any deviation from this spec is a bug.

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [JSON Schema](#2-json-schema)
3. [Segment (Grapheme) Division Rules](#3-segment-grapheme-division-rules)
4. [Silent Letter Rules](#4-silent-letter-rules)
5. [Syllable Division Rules](#5-syllable-division-rules)
6. [Stress Rules](#6-stress-rules)
7. [Consistency Rules](#7-consistency-rules)
8. [IPA & ARPABET Conventions](#8-ipa--arpabet-conventions)
9. [Standard Examples](#9-standard-examples)

---

## 1. Design Philosophy

### 1.1 Teaching-First, Not Linguistics-First

Every annotation decision is driven by one question:

> **"Does this help a Chinese primary/middle school student decode this word?"**

This means:
- Prefer **graphemes that are taught explicitly** in phonics lessons
- Prefer **syllable breaks that feel natural to say aloud** (clap-syllables)
- **Silent letters must always be identified** (Chinese learners tend to pronounce every letter)
- **Consistency across words** > linguistic optimality for any single word
- **This is pedagogy, not phonology**

### 1.2 Repeatability

The same word, annotated at different times, by different Claude instances,
MUST produce essentially the same result. This is achieved through strict
**Consistency Rules** (§7), not guidelines. Rules use the word **ALWAYS** or
**NEVER** — there is no "usually" or "preferably."

### 1.3 Three Audiences

1. **Frontend** — renders per-phoneme highlighting and syllable dots
2. **TTS engine** — uses IPA/ARPABET for pronunciation
3. **Teachers** — reviews annotations for classroom use

---

## 2. JSON Schema

### 2.1 Top-Level Structure

```json
{
  "word": "beautiful",
  "ipa": "/ˈbjuːtɪfəl/",
  "arpabet": "B Y UW1 T AH0 F AH0 L",
  "syllables": ["beau", "ti", "ful"],
  "stress": [1, 0, 0],
  "segments": [
    {"letters": "b",  "phoneme": "B",    "ipa": "b",   "silent": false, "syllable": 0},
    {"letters": "eau","phoneme": "Y UW",  "ipa": "juː", "silent": false, "syllable": 0},
    {"letters": "t",  "phoneme": "T",    "ipa": "t",   "silent": false, "syllable": 1},
    {"letters": "i",  "phoneme": "AH",   "ipa": "ɪ",   "silent": false, "syllable": 1},
    {"letters": "f",  "phoneme": "F",    "ipa": "f",   "silent": false, "syllable": 2},
    {"letters": "u",  "phoneme": "AH",   "ipa": "ə",   "silent": false, "syllable": 2},
    {"letters": "l",  "phoneme": "L",    "ipa": "l",   "silent": false, "syllable": 2}
  ]
}
```

### 2.2 Field Definitions

#### Top-Level

| Field | Type | Description |
|-------|------|-------------|
| `word` | string | The original word, preserving input case |
| `ipa` | string | IPA with `/.../` delimiters, primary stress `ˈ` before stressed syllable, secondary `ˌ` before secondarily-stressed syllable |
| `arpabet` | string | Space-separated ARPABET phonemes with CMU stress digits: `0` unstressed, `1` primary, `2` secondary |
| `syllables` | string[] | Substrings of `word` for each syllable. Joining MUST equal `word` exactly |
| `stress` | int[] | `0`/`1`/`2` per syllable. Length MUST equal `syllables.length`. Exactly one `1` |
| `segments` | object[] | Ordered grapheme-phoneme pairs. Joining `letters` MUST equal `word` |

#### Segment Object

| Field | Type | Description |
|-------|------|-------------|
| `letters` | string | Grapheme substring from `word`. All together reconstruct `word` |
| `phoneme` | string | ARPABET phoneme(s), space-separated. `""` when `silent: true` |
| `ipa` | string | IPA for this segment, no `/.../`. `""` when `silent: true` |
| `silent` | boolean | `true` if these letters produce NO sound |
| `syllable` | integer | 0-based index into `syllables[]` |

### 2.3 Validation Rules

1. `"".join(seg.letters for seg in segments)` MUST equal `word` (case-sensitive)
2. `len(syllables)` MUST equal `len(stress)`
3. Joining all non-silent `phoneme` values (stripped of stress digits) MUST match the base-phoneme sequence in `arpabet`
4. Every `seg.syllable` MUST be in `[0, len(syllables))`
5. `silent: true` ↔ `phoneme: ""` AND `ipa: ""`
6. `silent: false` → `phoneme` MUST NOT be `""`
7. `ipa` starts and ends with `/`

---

## 3. Segment (Grapheme) Division Rules

### 3.1 Core Principle

> **A segment = the smallest teaching grapheme.**

If a letter group is taught as a phonics unit, it stays together as ONE segment.
Silent letters are ALWAYS their own segments.

### 3.2 Multi-Letter Graphemes: ALWAYS ONE SEGMENT (Never Split)

#### Consonant Digraphs & Trigraphs

| Grapheme | Phoneme(s) | Example | Rule |
|----------|-----------|---------|------|
| `sh` | SH | ship, fish, wash | G7.1 |
| `ch` | CH | chin, much, chair | G7.2 |
| `ch` | K | school, chemistry, stomach | G7.2, §7.4 |
| `ch` | SH | chef, machine, brochure | G7.2, §7.4 |
| `th` | TH | thin, bath, through | G7.3 |
| `th` | DH | this, mother, the | G7.3 |
| `ph` | F | phone, graph, elephant | G7.4 |
| `wh` | W | what, when, where | S7.16 |
| `ng` | NG | sing, long, ring | G7.5 |
| `nk` | NG K | bank, think, pink | G7.6 |
| `ck` | K | back, clock, duck | G7.8 |
| `qu` | K W | queen, quick, quiet | G7.7 |

#### Vowel Digraphs (Always Whole)

| Grapheme | Phoneme(s) | Example |
|----------|-----------|---------|
| `ai` | EY | rain, wait, paint |
| `ay` | EY | day, play, stay |
| `ea` | IY, EH, EY | eat, bread, great |
| `ee` | IY | see, tree, green |
| `ei` | EY, IY, AY | vein, receive, height |
| `ey` | EY, IY | they, key |
| `ie` | IY, AY, IH | field, pie, sieve |
| `oa` | OW | boat, road, soap |
| `oe` | OW | toe, goes |
| `oi` | OY | coin, oil, voice |
| `oy` | OY | boy, toy, enjoy |
| `oo` | UW, UH | moon, book |
| `ou` | AW, OW, UW, UH | out, soul, you, would |
| `ow` | AW, OW | cow, snow |
| `au` | AO | author, sauce |
| `aw` | AO | saw, draw, law |
| `ew` | UW, Y UW | grew, few |
| `ui` | UW, IH | fruit, build |
| `ue` | UW, Y UW | blue, cue |

#### R-Controlled Vowels (Always Whole)

| Grapheme | Phoneme | Example |
|----------|---------|---------|
| `ar` | AA R | car, star, hard |
| `er` | ER | her, fern, sister |
| `ir` | ER | bird, first, girl |
| `ur` | ER | turn, nurse, curl |
| `or` | AO R | for, horse, north |
| `ear` | IH R, EH R, ER | hear, bear, earth |
| `air` | EH R | air, chair, fair |
| `are` | EH R | care, share, square |
| `ire` | AY ER | fire, tire, wire |
| `ore` | AO R | more, store, before |
| `ure` | Y UH R, UH R | pure, sure |

#### Trigraphs & Tetragraphs (Always Whole)

| Grapheme | Phoneme(s) | Example | Rule |
|----------|-----------|---------|------|
| `igh` | AY | high, light, night | G7.9 |
| `eigh` | EY | eight, weigh, neighbor | G7.10 |
| `ough` | OW, UW, AW, AH F, AO, AW F | though, through, bough, rough, thought, cough | G7.11 |
| `augh` | AO, AE F | caught, laugh | G7.12 |

#### Suffix Graphemes (Always Whole)

| Grapheme | Phoneme(s) | Example | Rule |
|----------|-----------|---------|------|
| `tion` | SH AH N | station, nation | G7.13 |
| `sion` | ZH AH N | vision, decision | G7.13 |
| `sion` | SH AH N | mission, passion | G7.13 |
| `cian` | SH AH N | musician, magician | G7.13 |
| `ture` | CH ER | nature, picture | G7.13 |
| `sure` | ZH ER | measure, treasure | G7.13 |
| `tial` | SH AH L | partial, essential | G7.13 |
| `cial` | SH AH L | special, official | G7.13 |
| `cious` | SH AH S | delicious, precious | G7.13 |
| `tious` | SH AH S | ambitious, cautious | G7.13 |

### 3.3 Graphemes Where Silent Letters ARE Split Out

These combinations contain a silent letter. The silent letter is ALWAYS
separated into its own segment. The remaining pronounced letters form their
own segment(s).

| Combination | Split Into | Example | Rule |
|-------------|-----------|---------|------|
| `kn-` | `k`(silent) + `n`→N | knee, knife, know | S7.2 |
| `wr-` | `w`(silent) + `r`→R | write, wrong, wrap | S7.3 |
| `gn-` | `g`(silent) + `n`→N | gnat, gnaw | S7.4 |
| `pn-` | `p`(silent) + `n`→N | pneumonia | S7.5 |
| `ps-` | `p`(silent) + `s`→S | psychology, psalm | S7.6 |
| `rh-` | `r`→R + `h`(silent) | rhyme, rhythm | S7.15 |
| `dge` | `d`(silent) + `ge`→JH | bridge, edge, judge | S7.7 |
| `tch` | `t`(silent) + `ch`→CH | catch, watch, match | S7.8 |
| `-mb` | `m`→M + `b`(silent) | comb, lamb, thumb | S7.9 |
| `-bt` | `b`(silent) + `t`→T | debt, doubt | S7.10 |
| `-stle` | `s`→S + `t`(silent) + `le`→AH L | castle, whistle | S7.11 |
| `-sten` | `s`→S + `t`(silent) + `en`→AH N | listen, fasten | S7.12 |
| `-ften` | `f`→F + `t`(silent) + `en`→AH N | often, soften | S7.13 |

### 3.4 Single-Letter Segments

Every single letter that is NOT silent and NOT part of a multi-letter grapheme
forms its own segment. Common phoneme mappings:

| Letter | Common Phonemes |
|--------|----------------|
| `a` | AE, AH, EY, AA, AO, EH, ER |
| `b` | B |
| `c` | K, S |
| `d` | D |
| `e` | EH, IY, IH, AH, ER, (silent) |
| `f` | F |
| `g` | G, JH |
| `h` | HH, (silent per §4.2) |
| `i` | IH, AY, IY |
| `j` | JH |
| `k` | K |
| `l` | L |
| `m` | M |
| `n` | N |
| `o` | OW, AA, AO, AH, UH, UW |
| `p` | P |
| `r` | R |
| `s` | S, Z |
| `t` | T |
| `u` | UH, UW, AH, Y UW, IH |
| `v` | V |
| `w` | W, (silent per §4.2) |
| `x` | K S, G Z |
| `y` | Y, IH, AY, IY |
| `z` | Z |

### 3.5 Magic E (Split Digraph)

In CVCe pattern, the final `e` is silent → its own segment:

```
make → m(M) + a(EY) + k(K) + e(silent)
bike → b(B) + i(AY) + k(K) + e(silent)
home → h(HH) + o(OW) + m(M) + e(silent)
```

---

## 4. Silent Letter Rules

### 4.1 The Fundamental Rule

> **EVERY silent letter MUST appear as its own segment with `silent: true`.**
>
> A silent letter is NEVER absorbed into an adjacent grapheme.

**CORRECT (knife):** `k`(silent) `n`→N `i`→AY `f`→F `e`(silent)
**WRONG (knife):** `kn`→N `i`→AY `f`→F `e`(silent) — k hidden inside "kn"

### 4.2 Word-Initial Silent Letters

| Pattern | Silent | Example | Segmentation |
|---------|--------|---------|-------------|
| `kn-` | `k` | knee, knife, know | `k`(silent) + `n`→N + ... |
| `wr-` | `w` | write, wrong, wrap | `w`(silent) + `r`→R + ... |
| `gn-` | `g` | gnat, gnaw, gnome | `g`(silent) + `n`→N + ... |
| `pn-` | `p` | pneumonia | `p`(silent) + `n`→N + ... |
| `ps-` | `p` | psychology, psalm | `p`(silent) + `s`→S + ... |
| `rh-` | `h` | rhyme, rhythm | `r`→R + `h`(silent) + ... |
| `h-` before `o` | `h` | honest, hour, honor | `h`(silent) + ... |
| `wh-` before `o` | `w` | who, whom, whose, whole | `w`(silent) + `h`→HH + ... |
| `wh-` other vowels | `h` | what, when, where, why | `w`→W + `h`(silent) + ... |

### 4.3 Word-Final Silent Letters

| Pattern | Silent | Example | Segmentation |
|---------|--------|---------|-------------|
| `-mb` | `b` (final) | comb, lamb, thumb | ... + `m`→M + `b`(silent) |
| `-bt` | `b` | debt, doubt | `d`→D + `b`(silent) + `t`→T |
| `-gn` | `g` | sign, design, foreign | ... + `g`(silent) + `n`→N |
| `-mn` | `n` (final) | autumn, column | ... + `m`→M + `n`(silent) |
| `-lm` | `l` | salmon, palm, calm | ... + `l`(silent) + `m`→M + ... |

### 4.4 Silent GH

When `gh` is inside `igh`/`eigh`/`ough`/`augh`, the tri-/tetragraph is kept
whole per G7.9–G7.12. The `gh` is NOT split because the entire grapheme is
a phonics teaching unit.

When `gh` is pronounced /f/ (laugh, cough, enough): ONE segment `gh`→F.

### 4.5 Silent Consonants in Clusters

| Pattern | Silent | Example | Segmentation |
|---------|--------|---------|-------------|
| `-stle` | `t` | castle, whistle | `s`→S + `t`(silent) + `le`→AH L |
| `-sten` | `t` | listen, fasten | `s`→S + `t`(silent) + `en`→AH N |
| `-ften` | `t` | often, soften | `f`→F + `t`(silent) + `en`→AH N |

### 4.6 Word-Specific Irregular Silent Letters

| Word | Silent | Origin |
|------|--------|--------|
| Wednesday | `d` (1st), `e` (2nd) | Historical |
| business | `i` (middle) | Historical |
| answer | `w` | Historical |
| sword | `w` | Historical |
| two | `w` | Historical |
| island | `s` | Folk etymology |
| aisle | `s` | French |
| foreign | `g` | French |
| receipt | `p` | Latin (recepta) |
| colonel | 2nd `o`, 2nd `l` | French/Italian |
| salmon | `l` | French |
| half | `l` | Historical |
| walk | `l` | Historical |
| could/should/would | `l` | Analogy |
| subtle | `b` | Latin (subtilis) |
| doubt | `b` | Latin (dubitare) |
| yacht | `ch` | Dutch |
| heir | `h` | French |
| muscle | `c` | Latin (musculus) |
| scene | `c` (before e) | Greek |
| science | `c` (before i) | Latin |
| scissors | `c` (before i), first `s` | Latin |

### 4.7 Word-Final Silent E

All word-final silent `e` is its own segment `e`(silent):
- **Magic E:** makes preceding vowel long: `make`, `bike`, `home`
- **No function:** `house`, `please`, `are`

---

## 5. Syllable Division Rules

### 5.1 Teaching Syllable Types

| Type | Description | Example |
|------|-------------|---------|
| **Closed** | Ends in consonant, short vowel | `cat`, `rab·bit` |
| **Open** | Ends in vowel, long vowel | `go`, `ti·ger` |
| **Magic E** | Vowel+C+Silent E | `cake`, `kite` |
| **R-Controlled** | Vowel+R forms one unit | `car`, `bir·d` |
| **Vowel Team** | Two+ vowels together | `rain`, `boat` |
| **Consonant-le** | -Cle ending | `ta·ble`, `cas·tle` |

### 5.2 Division Priority

1. **Compound words** → split between words: `sun·set`, `back·pack`
2. **Prefix/Suffix** → split at affix: `un·do`, `walk·ing`
3. **Consonant-le** → split before consonant: `ta·ble`, `bub·ble`
4. **VC/CV** (two consonants) → split between them: `rab·bit`
5. **V/CV** (one consonant) → consonant goes with second vowel: `ti·ger`
6. **VC/V** (short vowel) → consonant stays with first vowel: `riv·er`

### 5.3 Suffixes That Form Their Own Syllable

| Ending | Example | Syllables |
|--------|---------|-----------|
| `-tion` | station | sta · tion |
| `-sion` | vision | vi · sion |
| `-cian` | musician | mu · si · cian |
| `-ture` | picture | pic · ture |
| `-sure` | measure | mea · sure |
| `-cious` | delicious | de · li · cious |
| `-tious` | ambitious | am · bi · tious |
| `-cial` | special | spe · cial |
| `-tial` | partial | par · tial |
| `-ing` | walking | walk · ing |
| `-er` | teacher | teach · er |
| `-est` | biggest | big · gest |
| `-ly` | quickly | quick · ly |
| `-ment` | payment | pay · ment |
| `-ness` | kindness | kind · ness |
| `-ful` | helpful | help · ful |
| `-less` | hopeless | hope · less |
| `-ous` | famous | fa · mous |
| `-age` | village | vil · lage |
| `-ble` | table | ta · ble |
| `-ple` | apple | ap · ple |
| `-dle` | candle | can · dle |
| `-gle` | jungle | jun · gle |
| `-tle` | little | lit · tle |
| `-cle` | uncle | un · cle |

### 5.4 Prefixes That Form Their Own Syllable

| Prefix | Example | Syllables |
|--------|---------|-----------|
| `un-` | undo | un · do |
| `re-` | redo | re · do |
| `pre-` | preview | pre · view |
| `dis-` | dislike | dis · like |
| `mis-` | mistake | mis · take |
| `in-` | inside | in · side |
| `ex-` | exit | ex · it |
| `de-` | decode | de · code |
| `sub-` | subway | sub · way |
| `com-` | combine | com · bine |
| `con-` | connect | con · nect |
| `pro-` | protect | pro · tect |
| `trans-` | transport | trans · port |
| `inter-` | internet | in · ter · net |

### 5.5 How to Fill `syllables[]`

Each element of `syllables[]` is a SUBSTRING of the original word — NOT IPA:

```
word: "beautiful"
CORRECT:   ["beau", "ti", "ful"]
WRONG:     ["bjuː", "tɪ", "fəl"]   ← IPA, not allowed!
```

Joining all `syllables[]` MUST reconstruct the original word exactly.

### 5.6 Assigning `seg.syllable`

Each segment is assigned to the 0-based syllable whose substring contains it:

```
syllables[0]="beau" → segments b(B), eau(Y UW)   → syllable:0
syllables[1]="ti"   → segments t(T), i(AH)        → syllable:1
syllables[2]="ful"  → segments f(F), u(AH), l(L)  → syllable:2
```

---

## 6. Stress Rules

### 6.1 Stress Levels

| Level | ARPABET | IPA Mark | Meaning |
|-------|---------|----------|---------|
| Primary | `1` on vowel | `ˈ` before syllable | Loudest, longest |
| Secondary | `2` on vowel | `ˌ` before syllable | Medium stress |
| Unstressed | `0` on vowel | (no mark) | Reduced vowel (often schwa) |

### 6.2 The `stress` Array

```json
{"syllables": ["beau", "ti", "ful"], "stress": [1, 0, 0]}
```

- Length MUST equal `syllables.length`
- Exactly ONE element MUST be `1`
- Monosyllabic words: `"stress": [1]`

### 6.3 ARPABET Stress

Every vowel in `arpabet` MUST have a stress digit: `B Y UW1 T AH0 F AH0 L`

### 6.4 IPA Stress

- Primary: `/ˈbjuːtɪfəl/` — `ˈ` before stressed syllable
- Secondary: `/ˌɪnfərˈmeɪʃən/` — `ˌ` before secondary-stressed syllable

---

## 7. Consistency Rules

> **These are ABSOLUTE. The word "ALWAYS" or "NEVER" means no exceptions.
> If a rule conflicts with linguistic precision, the rule wins.**

### 7.1 Grapheme Integrity (G Rules)

**G7.1** `sh` ALWAYS one segment → SH. Never `s`+`h`.

**G7.2** `ch` ALWAYS one segment. Three pronunciations but never split:
- /tʃ/ → CH (chin, chair)
- /k/ → K (school, chemistry, stomach, chorus, character)
- /ʃ/ → SH (chef, machine, brochure)

**G7.3** `th` ALWAYS one segment. Never `t`+`h`:
- /θ/ → TH (thin, bath, through)
- /ð/ → DH (this, mother, the)

**G7.4** `ph` ALWAYS one segment → F. Never `p`+`h`.

**G7.5** `ng` ALWAYS one segment → NG. Never `n`+`g`.

**G7.6** `nk` ALWAYS one segment → NG K. Never `n`+`k` or `n`→NG+`k`→K.

**G7.7** `qu` ALWAYS one segment → K W. Never `q`+`u`.

**G7.8** `ck` ALWAYS one segment → K. Never `c`+`k`.

**G7.9** `igh` ALWAYS one segment → AY. Never split. The silent `gh` is
absorbed into the trigraph — `igh` is a teaching unit.
NEVER: `i`→AY + `g`(silent) + `h`(silent) or `ig`+`h`.

**G7.10** `eigh` ALWAYS one segment → EY. Never split.

**G7.11** `ough` ALWAYS one segment despite variable pronunciation:
though /oʊ/, through /uː/, thought /ɔː/, rough /ʌf/, cough /ɒf/, bough /aʊ/.
The tetragraph stays whole.

**G7.12** `augh` ALWAYS one segment: caught → AO, laugh → AE F.

**G7.13** Suffix graphemes ALWAYS stay whole: `tion`, `sion`, `cian`, `ture`,
`sure`, `tial`, `cial`, `cious`, `tious`.

**G7.14** All vowel digraphs listed in §3.2 ALWAYS stay whole.

**G7.15** All r-controlled vowels listed in §3.2 ALWAYS stay whole.

### 7.2 Silent Letter (S Rules)

**S7.1** EVERY silent letter is its own segment. One silent letter per segment
(with `gh` when silent and standalone being two segments: `g`(silent) + `h`(silent)).
Exception: when `gh` is inside `igh`/`eigh`/`ough`/`augh`, it is NOT split (G7.9–12).

**S7.2** `kn` at word start: ALWAYS `k`(silent) + `n`→N. NEVER `kn`→N.

**S7.3** `wr` at word start: ALWAYS `w`(silent) + `r`→R. NEVER `wr`→R.

**S7.4** `gn` at word start: ALWAYS `g`(silent) + `n`→N. NEVER `gn`→N.

**S7.5** `pn` at word start: ALWAYS `p`(silent) + `n`→N. NEVER `pn`→N.

**S7.6** `ps` at word start: ALWAYS `p`(silent) + `s`→S. NEVER `ps`→S.

**S7.7** `dge`: ALWAYS `d`(silent) + `ge`→JH. NEVER `dge`→JH.

**S7.8** `tch`: ALWAYS `t`(silent) + `ch`→CH. NEVER `tch`→CH.

**S7.9** `mb` at word end: ALWAYS `m`→M + `b`(silent). NEVER `mb`→M.

**S7.10** `bt` at word end: ALWAYS `b`(silent) + `t`→T. NEVER `bt`→T.

**S7.11** `stle` at word end: ALWAYS `s`→S + `t`(silent) + `le`→AH L.
NEVER `stle`→S AH L.

**S7.12** `sten` at word end: ALWAYS `s`→S + `t`(silent) + `en`→AH N.
NEVER `sten`→S AH N.

**S7.13** `ften` at word end: ALWAYS `f`→F + `t`(silent) + `en`→AH N.
NEVER `ften`→F AH N.

**S7.14** Word-final silent E: ALWAYS its own segment `e`(silent).

**S7.15** `rh` at word start: ALWAYS `r`→R + `h`(silent). NEVER `rh`→R.

**S7.16** `wh` at word start: context-dependent.
- Before `o` (who, whom, whose, whole): `w`(silent) + `h`→HH
- Before other vowels (what, when): `w`→W + `h`(silent)

### 7.3 Syllable (SY Rules)

**SY7.1** Compound words split at word boundary. `sun·set`, `back·pack`.

**SY7.2** Suffixes and prefixes in §5.3–5.4 ALWAYS split as described.

**SY7.3** Consonant-le ALWAYS forms its own syllable. `ta·ble`, `cas·tle`.

**SY7.4** `-tion`/`-sion`/`-cian` IS its own syllable. Split before it.

**SY7.5** `syllables[i]` is a SUBSTRING of `word`, not IPA.

### 7.4 Stress (ST Rules)

**ST7.1** `stress` array length MUST equal `syllables` length.

**ST7.2** Exactly ONE element in `stress` MUST be `1` (primary).

**ST7.3** Monosyllabic words: `"stress": [1]`.

**ST7.4** Every ARPABET vowel MUST have a stress digit (0/1/2).

### 7.5 General (GEN Rules)

**GEN7.1** `/.../` delimiters on top-level `ipa`. Segment `ipa` has NO delimiters.

**GEN7.2** ARPABET phonemes space-separated, vowels with stress digits.

**GEN7.3** Silent segments: `"phoneme": "", "ipa": "", "silent": true`.

**GEN7.4** Joining all `letters` MUST reconstruct `word`, preserving case.

**GEN7.5** `seg.syllable` is 0-based.

---

## 8. IPA & ARPABET Conventions

### 8.1 Vowels

| Keyword | IPA | ARPABET | Examples |
|---------|-----|---------|----------|
| TRAP (cat) | æ | AE | cat, bat, apple, laugh(US) |
| DRESS (bed) | ɛ | EH | bed, get, head, said |
| KIT (bit) | ɪ | IH | bit, sit, fish, pretty |
| LOT (hot) | ɒ | AA | hot, not, father, calm |
| STRUT (cut) | ʌ | AH | cut, but, sun, rough |
| FOOT (book) | ʊ | UH | book, foot, could, put |
| FLEECE (see) | iː | IY | see, meat, happy, key |
| FACE (cake) | eɪ | EY | cake, rain, day, they |
| PRICE (bike) | aɪ | AY | bike, light, my, pie |
| GOAT (home) | oʊ | OW | home, boat, snow, though |
| GOOSE (rule) | uː | UW | rule, moon, blue, through |
| MOUTH (cow) | aʊ | AW | cow, out, house, bough |
| CHOICE (boy) | ɔɪ | OY | boy, coin, oil |
| THOUGHT (saw) | ɔː | AO | saw, caught, door, thought |
| NURSE (her) | ɜːr/ɚ | ER | her, bird, turn, teacher |
| Schwa | ə | AH | about, pencil, sofa, circus |

### 8.2 Consonants

| Keyword | IPA | ARPABET |
|---------|-----|---------|
| p (pat) | p | P |
| b (bat) | b | B |
| t (top) | t | T |
| d (dog) | d | D |
| k (cat) | k | K |
| g (go) | ɡ | G |
| ch (church) | tʃ | CH |
| j (judge) | dʒ | JH |
| f (fan) | f | F |
| v (van) | v | V |
| th (thin) | θ | TH |
| th (this) | ð | DH |
| s (sit) | s | S |
| z (zip) | z | Z |
| sh (ship) | ʃ | SH |
| zh (vision) | ʒ | ZH |
| h (hat) | h | HH |
| m (map) | m | M |
| n (net) | n | N |
| ng (sing) | ŋ | NG |
| l (lip) | l | L |
| r (red) | r | R |
| w (wet) | w | W |
| y (yes) | j | Y |

---

## 9. Standard Examples

Each example is a complete, validated JSON annotation with the spec rule
that governs each key segmentation decision.

### 9.1 Short Vowels (CVC / Closed Syllable)

**cat** — Rule: single letters each form own segment
```json
{"word":"cat","ipa":"/kæt/","arpabet":"K AE1 T","syllables":["cat"],"stress":[1],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

**dog** — Rule: single letters
```json
{"word":"dog","ipa":"/dɒɡ/","arpabet":"D AO1 G","syllables":["dog"],"stress":[1],"segments":[{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0},{"letters":"o","phoneme":"AO","ipa":"ɒ","silent":false,"syllable":0},{"letters":"g","phoneme":"G","ipa":"ɡ","silent":false,"syllable":0}]}
```

**bus** — Rule: single letters
```json
{"word":"bus","ipa":"/bʌs/","arpabet":"B AH1 S","syllables":["bus"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"u","phoneme":"AH","ipa":"ʌ","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0}]}
```

### 9.2 Magic E (CVCe)

**make** — S7.14 e(silent), vowel → EY
```json
{"word":"make","ipa":"/meɪk/","arpabet":"M EY1 K","syllables":["make"],"stress":[1],"segments":[{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"a","phoneme":"EY","ipa":"eɪ","silent":false,"syllable":0},{"letters":"k","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**bike** — S7.14 e(silent), vowel → AY
```json
{"word":"bike","ipa":"/baɪk/","arpabet":"B AY1 K","syllables":["bike"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"k","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**home** — S7.14 e(silent), vowel → OW
```json
{"word":"home","ipa":"/hoʊm/","arpabet":"HH OW1 M","syllables":["home"],"stress":[1],"segments":[{"letters":"h","phoneme":"HH","ipa":"h","silent":false,"syllable":0},{"letters":"o","phoneme":"OW","ipa":"oʊ","silent":false,"syllable":0},{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

### 9.3 Consonant Digraphs (Always Whole)

**ship** — G7.1 sh→SH
```json
{"word":"ship","ipa":"/ʃɪp/","arpabet":"SH IH1 P","syllables":["ship"],"stress":[1],"segments":[{"letters":"sh","phoneme":"SH","ipa":"ʃ","silent":false,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"p","phoneme":"P","ipa":"p","silent":false,"syllable":0}]}
```

**chair** — G7.2 ch→CH, G7.15 air→EH R
```json
{"word":"chair","ipa":"/tʃɛr/","arpabet":"CH EH1 R","syllables":["chair"],"stress":[1],"segments":[{"letters":"ch","phoneme":"CH","ipa":"tʃ","silent":false,"syllable":0},{"letters":"air","phoneme":"EH R","ipa":"ɛr","silent":false,"syllable":0}]}
```

**phone** — G7.4 ph→F, S7.14 e(silent)
```json
{"word":"phone","ipa":"/foʊn/","arpabet":"F OW1 N","syllables":["phone"],"stress":[1],"segments":[{"letters":"ph","phoneme":"F","ipa":"f","silent":false,"syllable":0},{"letters":"o","phoneme":"OW","ipa":"oʊ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**sheep** — G7.1 sh→SH, G7.14 ee→IY
```json
{"word":"sheep","ipa":"/ʃiːp/","arpabet":"SH IY1 P","syllables":["sheep"],"stress":[1],"segments":[{"letters":"sh","phoneme":"SH","ipa":"ʃ","silent":false,"syllable":0},{"letters":"ee","phoneme":"IY","ipa":"iː","silent":false,"syllable":0},{"letters":"p","phoneme":"P","ipa":"p","silent":false,"syllable":0}]}
```

**school** — G7.2 ch→K (Greek origin), G7.14 oo→UW
```json
{"word":"school","ipa":"/skuːl/","arpabet":"S K UW1 L","syllables":["school"],"stress":[1],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"ch","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"oo","phoneme":"UW","ipa":"uː","silent":false,"syllable":0},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":0}]}
```

**thin** — G7.3 th→TH
```json
{"word":"thin","ipa":"/θɪn/","arpabet":"TH IH1 N","syllables":["thin"],"stress":[1],"segments":[{"letters":"th","phoneme":"TH","ipa":"θ","silent":false,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0}]}
```

**ring** — G7.5 ng→NG
```json
{"word":"ring","ipa":"/rɪŋ/","arpabet":"R IH1 NG","syllables":["ring"],"stress":[1],"segments":[{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"ng","phoneme":"NG","ipa":"ŋ","silent":false,"syllable":0}]}
```

**bank** — G7.6 nk→NG K
```json
{"word":"bank","ipa":"/bæŋk/","arpabet":"B AE1 NG K","syllables":["bank"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"nk","phoneme":"NG K","ipa":"ŋk","silent":false,"syllable":0}]}
```

**queen** — G7.7 qu→K W, G7.14 ee→IY
```json
{"word":"queen","ipa":"/kwiːn/","arpabet":"K W IY1 N","syllables":["queen"],"stress":[1],"segments":[{"letters":"qu","phoneme":"K W","ipa":"kw","silent":false,"syllable":0},{"letters":"ee","phoneme":"IY","ipa":"iː","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0}]}
```

### 9.4 Vowel Teams

**train** — G7.14 ai→EY
```json
{"word":"train","ipa":"/treɪn/","arpabet":"T R EY1 N","syllables":["train"],"stress":[1],"segments":[{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"ai","phoneme":"EY","ipa":"eɪ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0}]}
```

**boat** — G7.14 oa→OW
```json
{"word":"boat","ipa":"/boʊt/","arpabet":"B OW1 T","syllables":["boat"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"oa","phoneme":"OW","ipa":"oʊ","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

**book** — G7.14 oo→UH
```json
{"word":"book","ipa":"/bʊk/","arpabet":"B UH1 K","syllables":["book"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"oo","phoneme":"UH","ipa":"ʊ","silent":false,"syllable":0},{"letters":"k","phoneme":"K","ipa":"k","silent":false,"syllable":0}]}
```

**house** — G7.14 ou→AW, S7.14 e(silent)
```json
{"word":"house","ipa":"/haʊs/","arpabet":"HH AW1 S","syllables":["house"],"stress":[1],"segments":[{"letters":"h","phoneme":"HH","ipa":"h","silent":false,"syllable":0},{"letters":"ou","phoneme":"AW","ipa":"aʊ","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**boy** — G7.14 oy→OY
```json
{"word":"boy","ipa":"/bɔɪ/","arpabet":"B OY1","syllables":["boy"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"oy","phoneme":"OY","ipa":"ɔɪ","silent":false,"syllable":0}]}
```

**saw** — G7.14 aw→AO
```json
{"word":"saw","ipa":"/sɔː/","arpabet":"S AO1","syllables":["saw"],"stress":[1],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"aw","phoneme":"AO","ipa":"ɔː","silent":false,"syllable":0}]}
```

### 9.5 Trigraphs

**light** — G7.9 igh→AY (trigraph kept whole)
```json
{"word":"light","ipa":"/laɪt/","arpabet":"L AY1 T","syllables":["light"],"stress":[1],"segments":[{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":0},{"letters":"igh","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

**eight** — G7.10 eigh→EY
```json
{"word":"eight","ipa":"/eɪt/","arpabet":"EY1 T","syllables":["eight"],"stress":[1],"segments":[{"letters":"eigh","phoneme":"EY","ipa":"eɪ","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

### 9.6 OUGH Family (G7.11 — tetragraph always whole)

**through** — G7.11 ough→UW
```json
{"word":"through","ipa":"/θruː/","arpabet":"TH R UW1","syllables":["through"],"stress":[1],"segments":[{"letters":"th","phoneme":"TH","ipa":"θ","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"ough","phoneme":"UW","ipa":"uː","silent":false,"syllable":0}]}
```

**though** — G7.11 ough→OW
```json
{"word":"though","ipa":"/ðoʊ/","arpabet":"DH OW1","syllables":["though"],"stress":[1],"segments":[{"letters":"th","phoneme":"DH","ipa":"ð","silent":false,"syllable":0},{"letters":"ough","phoneme":"OW","ipa":"oʊ","silent":false,"syllable":0}]}
```

**thought** — G7.11 ough→AO
```json
{"word":"thought","ipa":"/θɔːt/","arpabet":"TH AO1 T","syllables":["thought"],"stress":[1],"segments":[{"letters":"th","phoneme":"TH","ipa":"θ","silent":false,"syllable":0},{"letters":"ough","phoneme":"AO","ipa":"ɔː","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

**rough** — G7.11 ough→AH F
```json
{"word":"rough","ipa":"/rʌf/","arpabet":"R AH1 F","syllables":["rough"],"stress":[1],"segments":[{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"ough","phoneme":"AH F","ipa":"ʌf","silent":false,"syllable":0}]}
```

**cough** — G7.11 ough→AO F
```json
{"word":"cough","ipa":"/kɒf/","arpabet":"K AO1 F","syllables":["cough"],"stress":[1],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"ough","phoneme":"AO F","ipa":"ɒf","silent":false,"syllable":0}]}
```

**bough** — G7.11 ough→AW
```json
{"word":"bough","ipa":"/baʊ/","arpabet":"B AW1","syllables":["bough"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"ough","phoneme":"AW","ipa":"aʊ","silent":false,"syllable":0}]}
```

**borough** — G7.11 ough→AH (schwa)
```json
{"word":"borough","ipa":"/ˈbʌrə/","arpabet":"B AH1 R AH0","syllables":["bor","ough"],"stress":[1,0],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"or","phoneme":"AH R","ipa":"ʌr","silent":false,"syllable":0},{"letters":"ough","phoneme":"AH","ipa":"ə","silent":false,"syllable":1}]}
```

### 9.7 AUGH Family

**daughter** — G7.12 augh→AO
```json
{"word":"daughter","ipa":"/ˈdɔːtər/","arpabet":"D AO1 T ER0","syllables":["daugh","ter"],"stress":[1,0],"segments":[{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0},{"letters":"augh","phoneme":"AO","ipa":"ɔː","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":1},{"letters":"er","phoneme":"ER","ipa":"ər","silent":false,"syllable":1}]}
```

**laugh** — G7.12 augh→AE F (US pronunciation)
```json
{"word":"laugh","ipa":"/læf/","arpabet":"L AE1 F","syllables":["laugh"],"stress":[1],"segments":[{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":0},{"letters":"augh","phoneme":"AE F","ipa":"æf","silent":false,"syllable":0}]}
```

**enough** — G7.11 ough→AH F
```json
{"word":"enough","ipa":"/ɪˈnʌf/","arpabet":"IH0 N AH1 F","syllables":["e","nough"],"stress":[0,1],"segments":[{"letters":"e","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"ough","phoneme":"AH F","ipa":"ʌf","silent":false,"syllable":1}]}
```

### 9.8 Silent Letter: kn- / wr- / gn-

**knife** — S7.2 k(silent), S7.14 e(silent)
```json
{"word":"knife","ipa":"/naɪf/","arpabet":"N AY1 F","syllables":["knife"],"stress":[1],"segments":[{"letters":"k","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"f","phoneme":"F","ipa":"f","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**write** — S7.3 w(silent), S7.14 e(silent)
```json
{"word":"write","ipa":"/raɪt/","arpabet":"R AY1 T","syllables":["write"],"stress":[1],"segments":[{"letters":"w","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

### 9.9 Silent Letter: -mb / -bt

**comb** — S7.9 m→M+b(silent)
```json
{"word":"comb","ipa":"/koʊm/","arpabet":"K OW1 M","syllables":["comb"],"stress":[1],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"o","phoneme":"OW","ipa":"oʊ","silent":false,"syllable":0},{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"b","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**debt** — S7.10 b(silent)+t→T
```json
{"word":"debt","ipa":"/dɛt/","arpabet":"D EH1 T","syllables":["debt"],"stress":[1],"segments":[{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0},{"letters":"e","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"b","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

**doubt** — S7.10 b(silent)+t→T, G7.14 ou→AW
```json
{"word":"doubt","ipa":"/daʊt/","arpabet":"D AW1 T","syllables":["doubt"],"stress":[1],"segments":[{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0},{"letters":"ou","phoneme":"AW","ipa":"aʊ","silent":false,"syllable":0},{"letters":"b","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

### 9.10 Silent Letter: dge / tch

**bridge** — S7.7 d(silent)+ge→JH
```json
{"word":"bridge","ipa":"/brɪdʒ/","arpabet":"B R IH1 JH","syllables":["bridge"],"stress":[1],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"d","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"ge","phoneme":"JH","ipa":"dʒ","silent":false,"syllable":0}]}
```

**catch** — S7.8 t(silent)+ch→CH
```json
{"word":"catch","ipa":"/kætʃ/","arpabet":"K AE1 CH","syllables":["catch"],"stress":[1],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"t","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"ch","phoneme":"CH","ipa":"tʃ","silent":false,"syllable":0}]}
```

### 9.11 Silent Letter: -stle / -sten

**castle** — S7.11 s→S+t(silent)+le→AH L, SY7.3 consonant-le
```json
{"word":"castle","ipa":"/ˈkæsəl/","arpabet":"K AE1 S AH0 L","syllables":["cas","tle"],"stress":[1,0],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"t","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"le","phoneme":"AH L","ipa":"əl","silent":false,"syllable":1}]}
```

**whistle** — S7.11, S7.16 w→W+h(silent)
```json
{"word":"whistle","ipa":"/ˈwɪsəl/","arpabet":"W IH1 S AH0 L","syllables":["whis","tle"],"stress":[1,0],"segments":[{"letters":"w","phoneme":"W","ipa":"w","silent":false,"syllable":0},{"letters":"h","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"t","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"le","phoneme":"AH L","ipa":"əl","silent":false,"syllable":1}]}
```

**listen** — S7.12 s→S+t(silent)+en→AH N
```json
{"word":"listen","ipa":"/ˈlɪsən/","arpabet":"L IH1 S AH0 N","syllables":["lis","ten"],"stress":[1,0],"segments":[{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"t","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"en","phoneme":"AH N","ipa":"ən","silent":false,"syllable":1}]}
```

### 9.12 Silent Letter: Word-Specific Irregular

**honest** — h(silent) before o
```json
{"word":"honest","ipa":"/ˈɒnɪst/","arpabet":"AA1 N AH0 S T","syllables":["hon","est"],"stress":[1,0],"segments":[{"letters":"h","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"o","phoneme":"AA","ipa":"ɒ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"e","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":1},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":1}]}
```

**hour** — h(silent) before ou
```json
{"word":"hour","ipa":"/aʊər/","arpabet":"AW1 ER0","syllables":["hour"],"stress":[1],"segments":[{"letters":"h","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"our","phoneme":"AW ER","ipa":"aʊər","silent":false,"syllable":0}]}
```

**answer** — w(silent), G7.15 er→ER
```json
{"word":"answer","ipa":"/ˈænsər/","arpabet":"AE1 N S ER0","syllables":["an","swer"],"stress":[1,0],"segments":[{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"w","phoneme":"","ipa":"","silent":true,"syllable":1},{"letters":"er","phoneme":"ER","ipa":"ər","silent":false,"syllable":1}]}
```

**sword** — w(silent), G7.15 or→AO R
```json
{"word":"sword","ipa":"/sɔːrd/","arpabet":"S AO1 R D","syllables":["sword"],"stress":[1],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"w","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"or","phoneme":"AO R","ipa":"ɔːr","silent":false,"syllable":0},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0}]}
```

**two** — w(silent)
```json
{"word":"two","ipa":"/tuː/","arpabet":"T UW1","syllables":["two"],"stress":[1],"segments":[{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0},{"letters":"w","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"o","phoneme":"UW","ipa":"uː","silent":false,"syllable":0}]}
```

**island** — s(silent)
```json
{"word":"island","ipa":"/ˈaɪlənd/","arpabet":"AY1 L AH0 N D","syllables":["is","land"],"stress":[1,0],"segments":[{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"s","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":1},{"letters":"a","phoneme":"AH","ipa":"ə","silent":false,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":1}]}
```

**sign** — g(silent) before n
```json
{"word":"sign","ipa":"/saɪn/","arpabet":"S AY1 N","syllables":["sign"],"stress":[1],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"g","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0}]}
```

**design** — g(silent), prefix de-
```json
{"word":"design","ipa":"/dɪˈzaɪn/","arpabet":"D IH0 Z AY1 N","syllables":["de","sign"],"stress":[0,1],"segments":[{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0},{"letters":"e","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"s","phoneme":"Z","ipa":"z","silent":false,"syllable":1},{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":1},{"letters":"g","phoneme":"","ipa":"","silent":true,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1}]}
```

**foreign** — g(silent), G7.14 ei→AH
```json
{"word":"foreign","ipa":"/ˈfɔːrɪn/","arpabet":"F AO1 R AH0 N","syllables":["for","eign"],"stress":[1,0],"segments":[{"letters":"f","phoneme":"F","ipa":"f","silent":false,"syllable":0},{"letters":"o","phoneme":"AO","ipa":"ɔː","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"ei","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"g","phoneme":"","ipa":"","silent":true,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1}]}
```

**receipt** — p(silent), G7.14 ei→IY
```json
{"word":"receipt","ipa":"/rɪˈsiːt/","arpabet":"R IH0 S IY1 T","syllables":["re","ceipt"],"stress":[0,1],"segments":[{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"e","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"c","phoneme":"S","ipa":"s","silent":false,"syllable":1},{"letters":"ei","phoneme":"IY","ipa":"iː","silent":false,"syllable":1},{"letters":"p","phoneme":"","ipa":"","silent":true,"syllable":1},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":1}]}
```

**salmon** — l(silent)
```json
{"word":"salmon","ipa":"/ˈsæmən/","arpabet":"S AE1 M AH0 N","syllables":["sal","mon"],"stress":[1,0],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"l","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":1},{"letters":"o","phoneme":"AH","ipa":"ə","silent":false,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1}]}
```

**autumn** — n(silent) word-end
```json
{"word":"autumn","ipa":"/ˈɔːtəm/","arpabet":"AO1 T AH0 M","syllables":["au","tumn"],"stress":[1,0],"segments":[{"letters":"au","phoneme":"AO","ipa":"ɔː","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":1},{"letters":"u","phoneme":"AH","ipa":"ə","silent":false,"syllable":1},{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":1},{"letters":"n","phoneme":"","ipa":"","silent":true,"syllable":1}]}
```

**subtle** — b(silent), SY7.3 consonant-le
```json
{"word":"subtle","ipa":"/ˈsʌtəl/","arpabet":"S AH1 T AH0 L","syllables":["sub","tle"],"stress":[1,0],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"u","phoneme":"AH","ipa":"ʌ","silent":false,"syllable":0},{"letters":"b","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":1},{"letters":"le","phoneme":"AH L","ipa":"əl","silent":false,"syllable":1}]}
```

**muscle** — c(silent), SY7.3 cle
```json
{"word":"muscle","ipa":"/ˈmʌsəl/","arpabet":"M AH1 S AH0 L","syllables":["mus","cle"],"stress":[1,0],"segments":[{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"u","phoneme":"AH","ipa":"ʌ","silent":false,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"c","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"le","phoneme":"AH L","ipa":"əl","silent":false,"syllable":1}]}
```

### 9.13 Irregular Words with Multiple Anomalies

**Wednesday** — d(silent,1st), e(silent,2nd), y(silent)
```json
{"word":"Wednesday","ipa":"/ˈwɛnzdeɪ/","arpabet":"W EH1 N Z D EY0","syllables":["Wed","nes","day"],"stress":[1,0,0],"segments":[{"letters":"W","phoneme":"W","ipa":"w","silent":false,"syllable":0},{"letters":"e","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"d","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":1},{"letters":"s","phoneme":"Z","ipa":"z","silent":false,"syllable":1},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":2},{"letters":"a","phoneme":"EY","ipa":"eɪ","silent":false,"syllable":2},{"letters":"y","phoneme":"","ipa":"","silent":true,"syllable":2}]}
```

**business** — i(silent), double-s ending
```json
{"word":"business","ipa":"/ˈbɪznɪs/","arpabet":"B IH1 Z N AH0 S","syllables":["busi","ness"],"stress":[1,0],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"u","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"s","phoneme":"Z","ipa":"z","silent":false,"syllable":0},{"letters":"i","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"e","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":1},{"letters":"s","phoneme":"","ipa":"","silent":true,"syllable":1}]}
```

**knowledge** — S7.2 k(silent), S7.7 d(silent)+ge→JH
```json
{"word":"knowledge","ipa":"/ˈnɒlɪdʒ/","arpabet":"N AA1 L AH0 JH","syllables":["know","ledge"],"stress":[1,0],"segments":[{"letters":"k","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"ow","phoneme":"AA","ipa":"ɒ","silent":false,"syllable":0},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":1},{"letters":"e","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"d","phoneme":"","ipa":"","silent":true,"syllable":1},{"letters":"ge","phoneme":"JH","ipa":"dʒ","silent":false,"syllable":1}]}
```

**psychology** — S7.6 p(silent), G7.2 ch→K
```json
{"word":"psychology","ipa":"/saɪˈkɒlədʒi/","arpabet":"S AY0 K AA1 L AH0 JH IY0","syllables":["psy","cho","lo","gy"],"stress":[0,1,0,0],"segments":[{"letters":"p","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"y","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"ch","phoneme":"K","ipa":"k","silent":false,"syllable":1},{"letters":"o","phoneme":"AA","ipa":"ɒ","silent":false,"syllable":1},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":2},{"letters":"o","phoneme":"AH","ipa":"ə","silent":false,"syllable":2},{"letters":"g","phoneme":"JH","ipa":"dʒ","silent":false,"syllable":3},{"letters":"y","phoneme":"IY","ipa":"i","silent":false,"syllable":3}]}
```

**queue** — ue(silent twice), G7.7 qu→K W
```json
{"word":"queue","ipa":"/kjuː/","arpabet":"K Y UW1","syllables":["queue"],"stress":[1],"segments":[{"letters":"q","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"u","phoneme":"Y","ipa":"j","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"u","phoneme":"UW","ipa":"uː","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**choir** — G7.2 ch→K W
```json
{"word":"choir","ipa":"/ˈkwaɪər/","arpabet":"K W AY1 ER0","syllables":["choir"],"stress":[1],"segments":[{"letters":"ch","phoneme":"K W","ipa":"kw","silent":false,"syllable":0},{"letters":"oi","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"r","phoneme":"ER","ipa":"ər","silent":false,"syllable":0}]}
```

**yacht** — ch(silent)
```json
{"word":"yacht","ipa":"/jɒt/","arpabet":"Y AA1 T","syllables":["yacht"],"stress":[1],"segments":[{"letters":"y","phoneme":"Y","ipa":"j","silent":false,"syllable":0},{"letters":"a","phoneme":"AA","ipa":"ɒ","silent":false,"syllable":0},{"letters":"ch","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0}]}
```

**colonel** — highly irregular (French/Italian)
```json
{"word":"colonel","ipa":"/ˈkɜːrnəl/","arpabet":"K ER1 N AH0 L","syllables":["colo","nel"],"stress":[1,0],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"o","phoneme":"ER","ipa":"ɜːr","silent":false,"syllable":0},{"letters":"l","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"o","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"e","phoneme":"AH","ipa":"ə","silent":false,"syllable":1},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":1}]}
```

### 9.14 CH Pronounced as Other Sounds

**machine** — G7.2 ch→SH (French origin)
```json
{"word":"machine","ipa":"/məˈʃiːn/","arpabet":"M AH0 SH IY1 N","syllables":["ma","chine"],"stress":[0,1],"segments":[{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"a","phoneme":"AH","ipa":"ə","silent":false,"syllable":0},{"letters":"ch","phoneme":"SH","ipa":"ʃ","silent":false,"syllable":1},{"letters":"i","phoneme":"IY","ipa":"iː","silent":false,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":1}]}
```

**chef** — G7.2 ch→SH (French origin)
```json
{"word":"chef","ipa":"/ʃɛf/","arpabet":"SH EH1 F","syllables":["chef"],"stress":[1],"segments":[{"letters":"ch","phoneme":"SH","ipa":"ʃ","silent":false,"syllable":0},{"letters":"e","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"f","phoneme":"F","ipa":"f","silent":false,"syllable":0}]}
```

**character** — G7.2 ch→K (Greek), SY7.3 cle
```json
{"word":"character","ipa":"/ˈkærɪktər/","arpabet":"K AE1 R AH0 K T ER0","syllables":["char","ac","ter"],"stress":[1,0,0],"segments":[{"letters":"ch","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"a","phoneme":"AE","ipa":"æ","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"a","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":1},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":2},{"letters":"er","phoneme":"ER","ipa":"ər","silent":false,"syllable":2}]}
```

**chorus** — G7.2 ch→K (Greek)
```json
{"word":"chorus","ipa":"/ˈkɔːrəs/","arpabet":"K AO1 R AH0 S","syllables":["cho","rus"],"stress":[1,0],"segments":[{"letters":"ch","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"o","phoneme":"AO","ipa":"ɔː","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"u","phoneme":"AH","ipa":"ə","silent":false,"syllable":1},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":1}]}
```

**chemistry** — G7.2 ch→K (Greek)
```json
{"word":"chemistry","ipa":"/ˈkɛmɪstri/","arpabet":"K EH1 M AH0 S T R IY0","syllables":["chem","is","try"],"stress":[1,0,0],"segments":[{"letters":"ch","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"e","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"i","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":1},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":2},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":2},{"letters":"y","phoneme":"IY","ipa":"i","silent":false,"syllable":2}]}
```

### 9.15 SC / CE / CI (C → S)

**scene** — c(silent) before e
```json
{"word":"scene","ipa":"/siːn/","arpabet":"S IY1 N","syllables":["scene"],"stress":[1],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"c","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"e","phoneme":"IY","ipa":"iː","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":0}]}
```

**science** — c(silent,1st before i), silent final e
```json
{"word":"science","ipa":"/ˈsaɪəns/","arpabet":"S AY1 AH0 N S","syllables":["sci","ence"],"stress":[1,0],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"c","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"i","phoneme":"AY","ipa":"aɪ","silent":false,"syllable":0},{"letters":"e","phoneme":"AH","ipa":"ə","silent":false,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1},{"letters":"c","phoneme":"S","ipa":"s","silent":false,"syllable":1},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":1}]}
```

**scissors** — c(silent,1st), ss→S+s(silent)

Hmm, "scissors" = /ˈsɪzərz/. Spelling: s-c-i-s-s-o-r-s. The first 'c' is silent (SC pronounced just as S), the 'ss' is one sound /z/, and 'or' → ER. Actually: s→S, c(silent), i→IH, ss→Z, or→ER, s(silent at end? No, 's' at end → Z).

Wait, "scissors" = /ˈsɪzərz/. Let me segment: s(S) c(silent) i(IH) ss(Z) or(ER) s(Z). But also... the final 's' is the plural morpheme. 

Actually let me give the correct segmentation:
- s → S
- c(silent)  
- i → IH
- ss → Z
- or → ER
- s → Z

Wait, `arpabet: S IH1 Z ER0 Z`. Syllables: scis·sors. Segments: s→S, c(silent), i→IH, ss→Z, or→ER, s→Z. Let me write this out properly and skip the inline thinking.

```json
{"word":"scissors","ipa":"/ˈsɪzərz/","arpabet":"S IH1 Z ER0 Z","syllables":["scis","sors"],"stress":[1,0],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"c","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"i","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"ss","phoneme":"Z","ipa":"z","silent":false,"syllable":0},{"letters":"or","phoneme":"ER","ipa":"ər","silent":false,"syllable":1},{"letters":"s","phoneme":"Z","ipa":"z","silent":false,"syllable":1}]}
```

### 9.16 Modal / Semi-Modal Auxiliaries

**could** — l(silent), G7.14 ou→UH
```json
{"word":"could","ipa":"/kʊd/","arpabet":"K UH1 D","syllables":["could"],"stress":[1],"segments":[{"letters":"c","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"ou","phoneme":"UH","ipa":"ʊ","silent":false,"syllable":0},{"letters":"l","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0}]}
```

**should** — l(silent), G7.1 sh→SH, G7.14 ou→UH
```json
{"word":"should","ipa":"/ʃʊd/","arpabet":"SH UH1 D","syllables":["should"],"stress":[1],"segments":[{"letters":"sh","phoneme":"SH","ipa":"ʃ","silent":false,"syllable":0},{"letters":"ou","phoneme":"UH","ipa":"ʊ","silent":false,"syllable":0},{"letters":"l","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0}]}
```

**would** — l(silent), G7.14 ou→UH
```json
{"word":"would","ipa":"/wʊd/","arpabet":"W UH1 D","syllables":["would"],"stress":[1],"segments":[{"letters":"w","phoneme":"W","ipa":"w","silent":false,"syllable":0},{"letters":"ou","phoneme":"UH","ipa":"ʊ","silent":false,"syllable":0},{"letters":"l","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0}]}
```

### 9.17 Common but Irregular

**people** — G7.14 eo→IY, SY7.3 ple
```json
{"word":"people","ipa":"/ˈpiːpəl/","arpabet":"P IY1 P AH0 L","syllables":["peo","ple"],"stress":[1,0],"segments":[{"letters":"p","phoneme":"P","ipa":"p","silent":false,"syllable":0},{"letters":"eo","phoneme":"IY","ipa":"iː","silent":false,"syllable":0},{"letters":"p","phoneme":"P","ipa":"p","silent":false,"syllable":1},{"letters":"le","phoneme":"AH L","ipa":"əl","silent":false,"syllable":1}]}
```

**one** — irregular
```json
{"word":"one","ipa":"/wʌn/","arpabet":"W AH1 N","syllables":["one"],"stress":[1],"segments":[{"letters":"o","phoneme":"W","ipa":"w","silent":false,"syllable":0},{"letters":"n","phoneme":"AH","ipa":"ʌ","silent":false,"syllable":0},{"letters":"e","phoneme":"N","ipa":"n","silent":false,"syllable":0}]}
```

**two** — w(silent)
```json
{"word":"two","ipa":"/tuː/","arpabet":"T UW1","syllables":["two"],"stress":[1],"segments":[{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":0},{"letters":"w","phoneme":"","ipa":"","silent":true,"syllable":0},{"letters":"o","phoneme":"UW","ipa":"uː","silent":false,"syllable":0}]}
```

**women** — irregular (o→IH)
```json
{"word":"women","ipa":"/ˈwɪmɪn/","arpabet":"W IH1 M AH0 N","syllables":["wom","en"],"stress":[1,0],"segments":[{"letters":"w","phoneme":"W","ipa":"w","silent":false,"syllable":0},{"letters":"o","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"m","phoneme":"M","ipa":"m","silent":false,"syllable":0},{"letters":"e","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":1}]}
```

**busy** — irregular (u→IH, s→Z)
```json
{"word":"busy","ipa":"/ˈbɪzi/","arpabet":"B IH1 Z IY0","syllables":["bus","y"],"stress":[1,0],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"u","phoneme":"IH","ipa":"ɪ","silent":false,"syllable":0},{"letters":"s","phoneme":"Z","ipa":"z","silent":false,"syllable":0},{"letters":"y","phoneme":"IY","ipa":"i","silent":false,"syllable":1}]}
```

**friend** — G7.14 ie→EH (irregular)
```json
{"word":"friend","ipa":"/frɛnd/","arpabet":"F R EH1 N D","syllables":["friend"],"stress":[1],"segments":[{"letters":"f","phoneme":"F","ipa":"f","silent":false,"syllable":0},{"letters":"r","phoneme":"R","ipa":"r","silent":false,"syllable":0},{"letters":"ie","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"n","phoneme":"N","ipa":"n","silent":false,"syllable":0},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0}]}
```

**beautiful** — G7.14 eau→Y UW, SY7.2 -ful suffix
```json
{"word":"beautiful","ipa":"/ˈbjuːtɪfəl/","arpabet":"B Y UW1 T AH0 F AH0 L","syllables":["beau","ti","ful"],"stress":[1,0,0],"segments":[{"letters":"b","phoneme":"B","ipa":"b","silent":false,"syllable":0},{"letters":"eau","phoneme":"Y UW","ipa":"juː","silent":false,"syllable":0},{"letters":"t","phoneme":"T","ipa":"t","silent":false,"syllable":1},{"letters":"i","phoneme":"AH","ipa":"ɪ","silent":false,"syllable":1},{"letters":"f","phoneme":"F","ipa":"f","silent":false,"syllable":2},{"letters":"u","phoneme":"AH","ipa":"ə","silent":false,"syllable":2},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":2}]}
```

### 9.18 SCHEDULE (Multiple Pronunciations)

**schedule (US)** — G7.2 ch→K (Greek) — actually "sch" → S K
```json
{"word":"schedule","ipa":"/ˈskɛdʒuːl/","arpabet":"S K EH1 JH UW0 L","syllables":["sched","ule"],"stress":[1,0],"segments":[{"letters":"s","phoneme":"S","ipa":"s","silent":false,"syllable":0},{"letters":"ch","phoneme":"K","ipa":"k","silent":false,"syllable":0},{"letters":"e","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"d","phoneme":"JH","ipa":"dʒ","silent":false,"syllable":0},{"letters":"u","phoneme":"UW","ipa":"uː","silent":false,"syllable":1},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":1},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":1}]}
```

**schedule (UK)** — ch→SH
```json
{"word":"schedule","ipa":"/ˈʃɛdjuːl/","arpabet":"SH EH1 D Y UW0 L","syllables":["sched","ule"],"stress":[1,0],"segments":[{"letters":"sch","phoneme":"SH","ipa":"ʃ","silent":false,"syllable":0},{"letters":"e","phoneme":"EH","ipa":"ɛ","silent":false,"syllable":0},{"letters":"d","phoneme":"D","ipa":"d","silent":false,"syllable":0},{"letters":"u","phoneme":"Y UW","ipa":"juː","silent":false,"syllable":1},{"letters":"l","phoneme":"L","ipa":"l","silent":false,"syllable":1},{"letters":"e","phoneme":"","ipa":"","silent":true,"syllable":1}]}
```

---

*End of Phonics Annotation Specification v1.0*
*All CamelliaQuill annotations MUST conform to this document.*
