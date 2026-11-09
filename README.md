# 2o7

2o7 is a browser game about holding a shelter through the night in Kenya, 2008.

## Run locally

Serve this directory over HTTP so the browser loads the external assets consistently:

```powershell
py -m http.server 8000
```

Open `http://localhost:8000/`.

## Project structure

- `index.html` - document structure, external dependencies, and cinematic overlay.
- `styles.css` - presentation and responsive controls.
- `game.js` - game state, rendering, input, audio, and gameplay rules.
- `game-core.js` - framework-free state transitions shared by the game and tests.
- `game-core.test.js` - automated tests for state and planning rules.

The game uses Three.js from cdnjs and the Bricolage Grotesque font from Google Fonts.

Intro and ending sequences are procedural Three.js camera cinematics rather than
large video files. They include a skip button and use a non-graphic, obscured
fail-state treatment.

The campaign now opens with a relief coordination centre. It offers five
fictionalized, geographically inspired operations: Nairobi, Rift Valley,
Western Kenya, the Coast, and Nyanza. These locations are grounded in the
regional displacement and mediation conditions of the 2007–08 crisis without
claiming to recreate specific real people or incidents.

Each operation now has a distinct procedural environment: dense informal
settlement lanes in Nairobi, volcanic cones and a hot fissure in the Rift
Valley, a river crossing in Western Kenya, working docks and ocean water on
the Coast, and a lake landing with boats and shoreline vegetation in Nyanza.
These are illustrative game environments, not surveyed geographic maps.

## Test

```powershell
npm test
```
