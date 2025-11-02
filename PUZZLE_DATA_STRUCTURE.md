# Puzzle Data Structure Guide

## Overview

All puzzle types use a single `puzzles` table with:
- **Common fields**: `id`, `title`, `difficulty`, `rating`, `rating_count`, `is_published`, `created_at`, `updated_at`, `challenge_date`, `type` (DailyChallenge), `is_featured`, `game_type`
- **Type-specific data**: Stored in `puzzle_data` JSON column

## Krossword Puzzles

**game_type**: `'krossword'` (or `nil` for legacy)

**puzzle_data structure**:
```json
{
  "clues": [
    { "clue": "A body of water", "answer": "OCEAN" },
    { "clue": "Large cat", "answer": "TIGER" }
  ],
  "description": "A fun crossword puzzle about nature",
  "layout": {
    "rows": 15,
    "cols": 15,
    "table": [["#", "O", "C", "E", "A", "N", "#"], ...],
    "result": [
      {
        "clue": "A body of water",
        "answer": "OCEAN",
        "startx": 1,
        "starty": 1,
        "position": 1,
        "orientation": "across"
      }
    ]
  }
}
```

**Required in puzzle_data**:
- `clues` (array) - At least one clue/answer pair

**Optional in puzzle_data**:
- `description` (string) - Puzzle description
- `layout` (hash) - Pre-generated crossword layout

**Legacy support**: Old puzzles may have `description` and `clues` columns populated (they're still read via model accessors).

## Konundrum Puzzles

**game_type**: `'konundrum'`

**puzzle_data structure**:
```json
{
  "clue": "Ocean Life",
  "words": ["OCEAN", "TIGER", "LIGHT"],
  "letters": ["O", "C", "E", "A", "N", "T", "I", "G", "E", "R", "L", "I", "G", "H", "T"],
  "seed": "optional-seed-string-for-reproducibility"
}
```

**Required in puzzle_data**:
- `clue` (string) - Theme, phrase, or "clueless" for extra difficulty
- `words` (array of strings) - The words to solve (typically 3 words)
- `letters` (array of single-character strings) - Shuffled letters from all words

**Optional in puzzle_data**:
- `seed` (string) - For reproducible letter shuffling

## KrissKross Puzzles

**game_type**: `'krisskross'`

**puzzle_data structure**:
```json
{
  "clue": "Ocean",
  "words": ["WATER", "WAVE", "CORAL"],
  "layout": {
    "rows": 4,
    "cols": 5,
    "table": [
      ["#", "#", "#", "W", "#"],
      ["C", "O", "R", "A", "L"],
      ["#", "#", "#", "V", "#"],
      ["W", "A", "T", "E", "R"]
    ],
    "result": [
      {
        "clue": "",
        "answer": "WATER",
        "startx": 1,
        "starty": 4,
        "position": 1,
        "orientation": "across"
      },
      {
        "clue": "",
        "answer": "WAVE",
        "startx": 4,
        "starty": 1,
        "position": 2,
        "orientation": "down"
      },
      {
        "clue": "",
        "answer": "CORAL",
        "startx": 1,
        "starty": 2,
        "position": 3,
        "orientation": "across"
      }
    ]
  }
}
```

**Required in puzzle_data**:
- `clue` (string) - Theme, phrase, or "clueless" for extra difficulty
- `words` (array of strings) - The words in the puzzle (typically 3-5 words, 4-8 letters each)
- `layout` (hash) - Pre-generated crossword layout
  - `layout.table` (array of arrays) - 2D grid with "#" for black squares, letters for cells
  - `layout.result` (array of hashes) - Word positions and metadata

## Validation

The `Puzzle` model validates `puzzle_data` structure based on `game_type`:

- **Krossword**: Validates `clues` array format, optional `layout` structure
- **Konundrum**: Validates `clue` string, `words` array, `letters` array (single chars), optional `seed`
- **KrissKross**: Validates `clue` string, `words` array, `layout` structure with `table` and `result`

## Model Accessors

The `Puzzle` model provides convenient accessors:

```ruby
# Krossword
puzzle.clues           # Array of clue/answer pairs
puzzle.description     # String
puzzle.layout          # Hash

# Konundrum
puzzle.clue            # String
puzzle.words           # Array of strings
puzzle.letters         # Array of single-character strings
puzzle.seed            # String or nil

# KrissKross
puzzle.clue            # String
puzzle.krisskross_words # Array of strings
puzzle.krisskross_layout # Hash
```

These accessors read from `puzzle_data` JSON, falling back to legacy columns when appropriate.

