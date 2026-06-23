# Goldeneye Decompilation

I've never done a decompilation before, this is a project for me to see how it works.

## Getting started

Requirements:

- Docker (or anything Docker compatible)
- [Just](https://github.com/casey/just)

You need to have a ROM of the game, place whichever you have at:

- `./baserom.pal.z64`
    - MD5: `cff69b70a8ad674a0efe5558765855c9`
    - SHA1: `167c3c433dec1f1eb921736f7d53fac8cb45ee31`
- `./baserom.ntsc_u.z64`
    - MD5: `70c525880240c1e838b8b1be35666c3b`
    - SHA1: `abe01e4aeb033b6c0836819f549c791b26cfde83`
- `./baserom.ntsc_j.z64`
    - MD5: `1880da358f875c0740d4a6731e110109`
    - SHA1: `2a5dade32f7fad6c73c659d2026994632c1b3174`

Then just run:

- `just make pal` for the PAL version
- `just make ntsc_u` for the NTSC-U version
- `just make ntsc_j` for the NTSC-J version
- `just make all` for all versions
