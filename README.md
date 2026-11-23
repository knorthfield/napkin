<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Napkin icon">
</p>

# Napkin

A calculator in a notepad, for macOS. Write a calculation on each line, in numbers and words.
The result of each line shows on the right.

```
# Holiday budget
Flights: $420 + $380                 $800.00
Hotel: 6 nights times $95            $570.00
Food: 7 days * $60                   $420.00
total                              $1,790.00
```

- **Words and symbols.** `8 times 9`, `20% of 340`, `6% off 40 EUR`, `$50 as a % of $100`,
  `sqrt 16`, `2 ^ 10`, `17 mod 5`, `255 in hex`.
- **Units.** Length, area, volume, weight, temperature, time, angle, data and screen units, with
  all SI prefixes: `5 ft 11 inches in cm`, `350 °F in °C`, `2 GB in MB`, `12 pt in px`.
- **Currencies.** `$30 in EUR`, `2k GBP in yen`. The rates are the daily rates of the European
  Central Bank.
- **Dates and time zones.** `today + 3 weeks`, `time in Madrid`, `9:30 am New York in London`.
- **Variables and totals.** `rate = 12.5`, then `40 * rate`. `prev` is the result above. `sum` and
  `average` use the lines above, up to the first empty line. The footer shows the total of all the
  results in the note.
- **Markdown notes.** Each note is a Markdown file in `~/Documents/Napkin`, with exactly the text
  that you typed. Headings, quotes and code blocks are text. List items are calculated.
  `Label:` before a calculation, `"quoted text"` and `// comment` lines are not calculated.

Click a result to copy it. **Edit › Copy Result** (⇧⌘C) copies the result of the line with the caret.

Napkin calculates on your Mac. The only network request gets the exchange rates from
[frankfurter.dev](https://frankfurter.dev).

## Install

Needs a Mac with Apple Silicon and macOS 26 or later. Napkin supports the current macOS and the
version before it.

With [Homebrew](https://brew.sh):

```sh
brew install --cask knorthfield/tap/napkin
```

Or download `Napkin.zip` from the [latest release](https://github.com/knorthfield/napkin/releases/latest).

## Build

```sh
brew install xcodegen
echo 'DEVELOPMENT_TEAM = <your team ID>' > Local.xcconfig
xcodegen generate
open Napkin.xcodeproj
```

`./test.sh` runs the tests.

## The language

| You write | Meaning |
| --- | --- |
| `+` `plus` `and` `with` | Add |
| `-` `minus` `subtract` `without` | Subtract |
| `*` `x` `times` `mul` `multiplied by` | Multiply |
| `/` `divide` `divide by` `divided by` | Divide |
| `^`, `mod` | Power, remainder |
| `&` `\|` `xor` `<<` `>>` | Bit operations |
| `in` `into` `as` `to` | Convert: `5 km in miles`, `255 in hex`, `in bin`, `in oct`, `in sci` |
| `k` `M` `thousand` `million` `billion` | Scales: `$2k`, `1.5M` |
| `0x1F` `0b101` `0o17` | Hexadecimal, binary and octal numbers |
| `5% of X`, `5% on X`, `5% off X` | The percentage of X, X plus it, X minus it |
| `A as a % of B` (also `on`, `off`) | A as a percentage of B |
| `5% of what is X` (also `on`, `off`) | The number of which X is 5% |
| `sqrt` `cbrt` `root 3 (x)` `abs` `log` `log 2 (x)` `ln` `fact` `round` `ceil` `floor` | Functions |
| `sin` `cos` `tan` `arcsin` `arccos` `arctan` `sinh` `cosh` `tanh` | Angles are in radians: `sin 30°` for degrees |
| `pi`, `e` | Constants |
| `em = 20px`, `ppi = 326` | The size of `em` (16 px) and the pixels in one inch (96) |
| `now` `time` `today` `tomorrow` `yesterday` `fromunix(n)` | Dates and times |

Words that mean nothing to the calculator are ignored: `$20 in euro - 5% discount`.
One-letter units and scales are case-sensitive: `m` is the metre, `M` is a million, `b` is a bit
and `B` is a byte. `in` is always a conversion: write `inch` for the unit.

## License

MIT. See [LICENSE](LICENSE).
