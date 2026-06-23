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

    if [ -z "$(docker images -q {{image_name}})" ]; then
        just image
        exit 0
    fi

    last_updated="$(docker inspect {{image_name}} | jq -r '.[].Created')"
    echo "Toolchain image last updated at: $(date -d "${last_updated}" $'+\033[33m%c\033[0m')"

    # check mod time on Dockerfile and rebuild if it is newer than the image
    if [ $(stat -c %Y Dockerfile) -gt $(date -d "$last_updated" +%s) ]; then
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
