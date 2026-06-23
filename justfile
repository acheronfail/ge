image_name := "ge/acheronfail"

_default:
    just -l

_check_image:
    if [ -z "$(docker images -q {{image_name}})" ]; then just image; fi

image:
    docker build --provenance=false --tag "{{image_name}}" .

bash: _check_image
    docker run -it --rm -v $(pwd):/goldeneye {{image_name}} bash

[arg('version', pattern='pal|ntsc_u|ntsc_j')]
_splat version:
    docker run -it --rm -v $(pwd):/goldeneye {{image_name}} splat split goldeneye.{{version}}.yaml
    sed -i '1iINCLUDE "splat.{{version}}/undefined_funcs_auto.txt"' splat.{{version}}/goldeneye.ld
    sed -i '1iINCLUDE "splat.{{version}}/undefined_syms_auto.txt"' splat.{{version}}/goldeneye.ld
    sed -i '1iINCLUDE "symbols.txt"' splat.{{version}}/goldeneye.ld

[arg('version', pattern='pal|ntsc_u|ntsc_j')]
make version: _check_image
    if [ ! -d  "splat.{{version}}" ]; then just _splat {{version}}; fi
    docker run -it --rm -v $(pwd):/goldeneye {{image_name}} make VERSION={{version}}

make_all: _check_image
    just make pal
    just make ntsc_u
    just make ntsc_j

clean:
    rm -rf build splat.*
    docker rmi {{image_name}} || true
