# Chord Formatting Guide

## Problem Solved

The previous chord system had issues where:
1. Chords were stored as one continuous line without proper formatting
2. No alignment between chords and lyrics
3. Difficult to read and understand chord progressions

## New Solution

### 1. Intelligent Chord Parsing
- **Continuous String Handling**: The system now intelligently parses continuous chord strings (like "C F G Am Dm G") and distributes them across lyric lines
- **Automatic Line Breaking**: Chords are automatically split into lines that correspond to lyric lines
- **Proper Positioning**: Chords are positioned above lyrics with proper spacing

### 2. Manual Input Enhancement
- **Chord Input Field**: Added a dedicated chord input field in the manual song entry screen
- **Formatting Help**: Built-in help system with examples and tips
- **Auto-Formatting**: Button to automatically format continuous chord strings
- **Validation**: Real-time validation of chord formats

### 3. Structured Storage
- **JSON Format**: Chords are now stored in a structured JSON format that includes:
  - Line-by-line chord data
  - Positioning information
  - Raw chord and lyric data
  - Version information for future compatibility

## How to Use

### For Manual Input:
1. **Enter Lyrics**: Type or paste your lyrics with line breaks
2. **Enter Chords**: Type chords with spaces between them
   - Use spaces to position chords above specific words
   - Use Enter key for new lines
   - Example: `C    F    G` (spaces position the chord)
3. **Auto-Format**: If you have a continuous chord string, use the "Format Continuous Chords" button
4. **Get Help**: Use the help button for detailed formatting guidance

### For API-Imported Songs:
- The system automatically parses continuous chord strings from the API
- Chords are distributed intelligently across lyric lines
- Proper positioning is calculated automatically

## Examples

### Manual Input Example:
```
Chords:
C    F    G
Am   Dm   G
C    F    G

Lyrics:
This is the first line
This is the second line  
This is the third line
```

### Continuous String Auto-Format:
```
Input: "C F G Am Dm G C F G"
Output: 
C F G
Am Dm G  
C F G
```

## Technical Implementation

### Key Functions:
1. `_extractAllChords()`: Extracts individual chords from continuous string
2. `_distributeChordsAcrossLyrics()`: Intelligently distributes chords across lyric lines
3. `_parseChordLineWithPositioning()`: Calculates proper positioning for display
4. `formatContinuousChordsForManualInput()`: Formats continuous strings for manual input
5. `validateAndFormatManualChords()`: Validates and formats manual input

### Storage Format:
```json
{
  "version": "1.0",
  "lines": [
    {
      "type": "chords",
      "chords": [
        {"note": "C", "pre_spaces": 2},
        {"note": "F", "pre_spaces": 8},
        {"note": "G", "pre_spaces": 14}
      ],
      "lyric": "This is the first line"
    }
  ],
  "raw_chords": "C F G Am Dm G",
  "raw_lyrics": "This is the first line\nThis is the second line",
  "formatted_chords": "C F G Am Dm G"
}
```

## Benefits

1. **Better Readability**: Chords are properly formatted and aligned with lyrics
2. **Easier Input**: Manual input with helpful guidance and auto-formatting
3. **Consistent Display**: All songs display chords in a consistent, readable format
4. **Future-Proof**: Structured storage allows for easy updates and improvements
5. **Backward Compatible**: Old chord formats are still supported

## Testing

Run the chord parsing tests:
```bash
flutter test test/chord_parsing_test.dart
```

This will verify that:
- Continuous chord strings are properly parsed
- Chord validation works correctly
- Empty inputs are handled gracefully
- Formatting functions work as expected 