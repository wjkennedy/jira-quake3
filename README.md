# Lotus 1-2-3 Forge App for Confluence

A Lotus 1-2-3 spreadsheet application packaged as a Forge app for Atlassian Confluence. This brings the classic spreadsheet experience to Confluence pages with save functionality.

## Features

- 📊 Classic Lotus 1-2-3 spreadsheet interface
- 💾 Save spreadsheets to Confluence storage
- 📝 Formula support with cell references
- 🎨 Multiple cell formats (Number, Currency, Percent, Date)
- ⌨️ Keyboard navigation and shortcuts
- 📋 Copy/paste functionality
- 🔢 100 rows x 26 columns (expandable)
- 🖱️ Click and double-click cell editing

## Quick Start

### Prerequisites

1. Install the Forge CLI:
```bash
npm install -g @forge/cli
```

### Deploy

1. **Login to Forge**:
```bash
forge login
```

2. **Register the app** (first time only):
```bash
forge register
```

3. **Deploy**:
```bash
forge deploy
```

4. **Install to your Confluence site**:
```bash
forge install
```

## Usage

### Adding Lotus 1-2-3 to a Confluence Page

1. Edit any Confluence page
2. Type `/lotus` or `/spreadsheet` to insert the macro
3. The Lotus 1-2-3 spreadsheet will appear embedded in your page
4. Start entering data and formulas

### Keyboard Shortcuts

- **Arrow Keys** - Navigate between cells
- **Enter** - Start editing current cell / Move down
- **Tab** - Move to next cell (right)
- **F2** - Edit current cell
- **Escape** - Cancel editing
- **Delete** - Clear current cell
- **Ctrl+C** - Copy cell
- **Ctrl+V** - Paste cell

### Formula Support

Lotus 1-2-3 supports formulas starting with `=`:

```
=A1+B1          // Add two cells
=A1*2           // Multiply by constant
=SUM(A1:A10)    // Sum a range (planned)
=(A1+A2)/2      // Complex formulas
```

### Cell Formats

- **General** - Default text/number display
- **Number** - Fixed decimal places
- **Currency** - Dollar sign with 2 decimals
- **Percent** - Percentage display
- **Date** - Date formatting

### Saving Data

Click the **Save** button in the toolbar to persist your spreadsheet data to Confluence storage. Each macro instance maintains its own independent spreadsheet.

## Technical Architecture

### Forge Integration

- **Confluence Macro**: Embeds the spreadsheet in any Confluence page
- **Forge Storage**: Persists spreadsheet data per macro instance
- **Static Resources**: HTML/CSS/JS served from Forge infrastructure

### Components

```
lotus-123-forge-app/
├── manifest.yml              # Forge app configuration
├── package.json              # Dependencies
├── src/
│   └── index.js             # Forge resolver (save/load handlers)
├── static/lotus123/
│   ├── index.html           # Main UI
│   ├── styles.css           # Lotus 1-2-3 themed styling
│   ├── lotus-engine.js      # Spreadsheet engine
│   ├── dosbox.js            # DOSBox WASM (future)
│   └── lotus-logo.png       # App icon
└── README.md
```

### Current Implementation

**Version 1.0** uses a custom JavaScript spreadsheet engine that replicates core Lotus 1-2-3 functionality:

- Cell grid rendering
- Formula evaluation
- Basic functions
- Cell formatting
- Keyboard navigation

### Future Enhancement: DOSBox Integration

**Version 2.0** will integrate actual Lotus 1-2-3 via DOSBox WebAssembly:

- Real Lotus 1-2-3 DOS executable
- Authentic retro experience
- Full feature compatibility
- File import/export (.WK1, .WKS)

## Development

### Local Testing

```bash
# Start local development tunnel
forge tunnel

# Access via the provided URL
```

### Modifying the Spreadsheet Engine

Edit `static/lotus123/lotus-engine.js` to customize:
- Cell dimensions and layout
- Formula parser and evaluator
- Rendering styles
- Additional functions

### Adding Formula Functions

Extend the `computeValue()` method in `lotus-engine.js`:

```javascript
// Add new function
evalFormula = evalFormula.replace(/AVERAGE$$([^)]+)$$/gi, (match, range) => {
  // Implementation
  return result
})
```

## API Reference

### Forge Resolver Functions

**macroHandler**
- Initializes macro with unique ID
- Returns configuration to UI

**resolveMacro**
- Loads saved spreadsheet data
- Returns data to UI

**saveSpreadsheet**
- Persists spreadsheet state
- Parameters: `{ macroId, data }`

**loadSpreadsheet**
- Retrieves saved spreadsheet
- Parameters: `{ macroId }`

## Permissions

Required Forge permissions:
- `storage:app` - Save/load spreadsheet data
- `read:confluence-content.all` - Read page context
- `write:confluence-content` - Embed macro in pages

## Roadmap

### Phase 1: Core Functionality ✅
- Basic spreadsheet grid
- Cell editing and navigation
- Simple formulas
- Save/load to Forge storage
- Confluence macro integration

### Phase 2: Enhanced Features (Planned)
- More formula functions (SUM, AVERAGE, IF, VLOOKUP)
- Cell range selection
- Cell formatting (bold, italic, alignment)
- Row/column insert/delete
- Undo/redo

### Phase 3: DOSBox Integration (Future)
- Compile DOSBox to WebAssembly
- Mount Lotus 1-2-3 DOS executable
- Virtual file system for .WK1 files
- Import/export capabilities

### Phase 4: Collaboration (Future)
- Real-time multi-user editing
- Change tracking
- Comments and annotations
- Export to modern formats (Excel, CSV)

## Browser Compatibility

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Requires HTML5 Canvas and ES6 JavaScript support.

## Performance

- Lightweight JavaScript engine
- 100 rows x 26 columns rendered efficiently
- Instant save/load via Forge storage
- No external dependencies

## Troubleshooting

**Macro won't load:**
- Ensure app is deployed: `forge deploy`
- Check permissions in manifest.yml
- Verify installation: `forge install --upgrade`

**Data not saving:**
- Check browser console for errors
- Verify Forge storage permissions
- Ensure unique macro ID is generated

**Formulas showing #ERROR:**
- Check formula syntax (must start with =)
- Verify cell references exist
- Complex formulas may need debugging

## License

MIT License

This is an independent recreation inspired by the original Lotus 1-2-3 spreadsheet software by Lotus Software (IBM).

## Credits

- Original Lotus 1-2-3: Lotus Software / IBM
- Forge Platform: Atlassian
- DOSBox: DOSBox Team (for future integration)

## Resources

- [Forge Developer Guide](https://developer.atlassian.com/platform/forge/)
- [Confluence Macros](https://developer.atlassian.com/platform/forge/manifest-reference/modules/confluence-macro/)
- [Lotus 1-2-3 Documentation](https://en.wikipedia.org/wiki/Lotus_1-2-3)

---

**Note**: This is a recreation of Lotus 1-2-3 functionality in modern JavaScript. Full DOS emulation coming in future versions!
