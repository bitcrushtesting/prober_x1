#!/bin/sh
# Export the PCB meshes from KiCad and render the README images.
# Needs kicad-cli (KiCad 9+) and openscad on the PATH, or set KICAD_CLI / OPENSCAD.
set -e
cd "$(dirname "$0")"

KICAD_CLI=${KICAD_CLI:-kicad-cli}
OPENSCAD=${OPENSCAD:-openscad}
MODELS=${KICAD_3DMODELS:-$(dirname "$(command -v "$KICAD_CLI")")/../SharedSupport/3dmodels}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# The footprints reference the KiCad 8 .wrl models, only the .step files ship
# with current versions: point the board copy at those.
sed -e "s#\${KICAD8_3DMODEL_DIR}#$MODELS#g" -e 's#\.wrl"#.step"#g' \
    ../pcb/carrier/carrier.kicad_pcb > "$tmp/carrier.kicad_pcb"

# Origins = top left board corner (carrier) and end hole (arm)
"$KICAD_CLI" pcb export stl -f --user-origin 90x100mm -o pcb/carrier.stl "$tmp/carrier.kicad_pcb"
"$KICAD_CLI" pcb export stl -f --board-only --user-origin 90x100mm -o pcb/carrier_board.stl ../pcb/carrier/carrier.kicad_pcb
"$KICAD_CLI" pcb export stl -f --board-only --user-origin 100x90mm -o pcb/mounting_arm.stl ../pcb/mounting_arm/mounting_arm.kicad_pcb

img=../docs/img
size=1600,1200
render() { name=$1; shift; "$OPENSCAD" --imgsize $size --colorscheme Tomorrow -o "$img/$name.png" "$@"; }

render assembly --projection p --camera 105,105,15,58,0,30,600  -D 'view="full"'      assembly.scad
render bottom   --projection p --camera 105,105,25,122,0,30,600 -D 'view="full"'      assembly.scad
render dut_mount --projection p --camera 0,-15,0,62,0,150,150   -D 'view="dut_mount"' assembly.scad
render top      --projection o --camera 0,0,0,0,0,0,500 --viewall --autocenter -D 'view="full"' assembly.scad
