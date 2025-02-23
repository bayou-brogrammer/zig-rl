== Zig Rougelike ==

## Building

This is tested on Windows and Linux. On Linux (and likely on a Mac, although
this is untested), make sure SDL2 is installed including SDL_ttf and SDL_image.
On Windows the repository contains the necessary SDL2 files so no installation is
required.

Then just run:

```bash
zig build run
```

If you are playing and not developing,
consider

```bash
zig build run -Doptimize=ReleaseFast
```

to get a smoother experience, but note that it will take more time the first time it is run.
