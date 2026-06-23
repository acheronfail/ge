set unstable

image_name := "ge/acheronfail"

sha1s := "
       pal:167c3c433dec1f1eb921736f7d53fac8cb45ee31
    ntsc_u:abe01e4aeb033b6c0836819f549c791b26cfde83
    ntsc_j:2a5dade32f7fad6c73c659d2026994632c1b3174
"
sha1(version) := shell("echo '" + sha1s + "' | grep '" + version + "' | cut -d':' -f2")

_default:
    just -l

_check_image:
    #!/usr/bin/env bash
    set -euo pipefail

    # GNU (Linux) and BSD (macOS) coreutils differ; detect and route accordingly.
    iso_to_epoch() {
        if date --version >/dev/null 2>&1; then
            date -d "$1" +%s
        else
            # strip fractional seconds/timezone, interpret the ISO8601 UTC stamp
            date -j -u -f "%Y-%m-%dT%H:%M:%S" "${1:0:19}" +%s
        fi
    }
    human_time() { if date --version >/dev/null 2>&1; then date -d "@$1" "$2"; else date -r "$1" "$2"; fi }
    mtime() { if stat --version >/dev/null 2>&1; then stat -c %Y "$1"; else stat -f %m "$1"; fi }

    if [ -z "$(docker images -q {{image_name}})" ]; then
        just image
        exit 0
    fi

    last_updated="$(docker inspect {{image_name}} | jq -r '.[].Created')"
    last_updated_epoch="$(iso_to_epoch "$last_updated")"
    echo "Toolchain image last updated at: $(human_time "$last_updated_epoch" $'+\033[33m%c\033[0m')"

    # check mod time on Dockerfile and rebuild if it is newer than the image
    if [ "$(mtime Dockerfile)" -gt "$last_updated_epoch" ]; then
        echo "Dockerfile is newer than the image, rebuilding..."
        just image
    fi

image:
    docker build --provenance=false --tag "{{image_name}}" .

bash: _check_image
    docker run -it --rm -v $(pwd):/goldeneye {{image_name}} bash

[arg('version', pattern='pal|ntsc_u|ntsc_j')]
_splat version:
    docker run -i --rm -v $(pwd):/goldeneye -e SHA1={{sha1(version)}} -e VERSION={{version}} {{image_name}} \
        envsubst < splat.yaml > build/goldeneye.{{version}}.yaml
    docker run -it --rm -v $(pwd):/goldeneye {{image_name}} splat split build/goldeneye.{{version}}.yaml
    sed -i '1iINCLUDE "splat.{{version}}/undefined_funcs_auto.txt"' splat.{{version}}/goldeneye.ld
    sed -i '1iINCLUDE "splat.{{version}}/undefined_syms_auto.txt"' splat.{{version}}/goldeneye.ld
    sed -i '1iINCLUDE "symbols.txt"' splat.{{version}}/goldeneye.ld

[arg('version', pattern='pal|ntsc_u|ntsc_j')]
make version: _check_image
    @mkdir -p build
    @if [ ! -d  "splat.{{version}}" ]; then just _splat {{version}}; fi
    docker run -it --rm -v $(pwd):/goldeneye {{image_name}} make VERSION={{version}}
    echo '{{sha1(version)}}  build/goldeneye.{{version}}.z64' | sha1sum -c -

make_all: _check_image
    just make pal
    just make ntsc_u
    just make ntsc_j

clean:
    rm -rf build splat.*
    docker rmi {{image_name}} || true
