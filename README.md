<h1 align="center">Map Tag</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=48VfeNLRWZc"><img src="https://img.youtube.com/vi/48VfeNLRWZc/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin lets admins draw freehand lines on the map using beams, perfect for signatures, tags, or simple shapes.
Hold +drawline and move around to draw; release to lift the pen and start a new stroke without connecting it to the last one.
Drawings are saved per map and automatically loaded on every map start.
- Draw multi-stroke lines in real time using beam entities
- Strokes are separated automatically (no connecting line between unrelated shapes)
- Configurable beam width, noise, color, and color mode (unified or random per segment)
- Optional color cycling on a set frequency
- Drawings persist across map changes via a per-map save file

## 📋 Requirements
- ReGameDLL
- AMX Mod X 1.10+

## 💬 Commands
- `+drawline / -drawline` - Hold to draw, release to lift the pen.
- `maptag_clear` - Clears the current drawing.
- `maptag_save` - Saves the current drawing to file.

## ⚙️ Configuration
```ini
# maptag_line                   = Enable/disable line rendering (0/1)
# maptag_beam_width             = Beam width
# maptag_beam_noise             = Beam noise/jitter
# maptag_beam_color             = Beam color (R G B A)
# maptag_beam_color_random      = Enable random color cycling (0/1)
# maptag_beam_color_frequency   = Frequency (seconds) of random color change
# maptag_beam_color_mode        = Color mode (0 - Unified, 1 - Random per segment)
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=48VfeNLRWZc)
