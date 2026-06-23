image_name := "ge/acheronfail"

_default:
    just -l

_check_image:
    if [ -z "$(docker images -q {{ image_name }})" ]; then just image; fi

image:
    docker build --provenance=false --tag "{{ image_name }}" .

bash: _check_image
    docker run -it --rm -v $(pwd):/goldeneye {{ image_name }} bash

make: _check_image
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -d  "splat.pal" ]; then
        docker run -it --rm -v $(pwd):/goldeneye {{ image_name }} splat split goldeneye.pal.yaml
        sed -i '1iINCLUDE "splat.pal/undefined_funcs_auto.txt"' splat.pal/goldeneye.ld
        sed -i '1iINCLUDE "splat.pal/undefined_syms_auto.txt"' splat.pal/goldeneye.ld
        sed -i '1iINCLUDE "symbols.txt"' splat.pal/goldeneye.ld
    fi
    docker run -it --rm -v $(pwd):/goldeneye {{ image_name }} make

clean:
    rm -rf build splat.*
    docker rmi {{ image_name }} || true
