// PROBER X1 - Corner Connector
//
// Joins two carrier PCBs at 90 degrees. Four corners + four carriers form a
// closed square frame. The corner is a square block: each carrier end sits in
// a 1.6 mm pocket between the raised core (end stop) and the raised inner
// square (guide for the inner PCB edge). Where both carrier corners meet, a 45
// degree relief slot keeps the PCB corners free. Each carrier end is held
// by two M3x8 button head screws into heat-set thread inserts. A 6x2 mm
// neodymium magnet sits in the bottom so the frame holds on a steel plate.
//
// The block is a hollow shell, open at the bottom. Columns under the inserts
// and the magnet plus a rib cross keep every ceiling span short enough to
// bridge, so it prints upright without supports.
//
// Origin = outer corner, bottom face. Carrier A runs along +X, carrier B along +Y.

/* [Render] */
part = "corner"; // [corner, assembly]

/* [Carrier PCB] (from pcb/carrier/carrier.kicad_pcb) */
pcb_length    = 130;
pcb_width     = 40;
pcb_thickness = 1.6;
hole_inset    = 7.5;   // corner hole distance from PCB end and long edges
pcb_clearance = 0.2;   // gap between PCB end and the pocket wall

/* [Body] */
arm_length    = 16;    // overlap under each carrier end
relief_width  = 1.5;   // 45 degree relief slot where the PCB corners meet
relief_length = 3;     // slot length on each side of the corner point
height        = 40;    // total height = carrier top surface
chamfer       = 1;

/* [Shell] */
wall          = 2.4;
top_plate     = 3;     // ceiling under the PCB pockets
rib           = 2;
column_wall   = 2.4;   // around insert holes and magnet pocket

/* [Thread insert] (M3 x 4 mm) */
insert_dia    = 4.0;
insert_length = 4;
insert_depth  = 7;     // > insert length so the M3x8 screw tip (6.4 mm) has room
insert_lead   = 0.4;   // entry chamfer

/* [Magnet] */
magnet_dia    = 6;
magnet_height = 2;
magnet_clear  = 0.2;   // diametral clearance for glue
magnet_cover  = 0;     // > 0 = closed pocket for a print pause (e.g. 0.6)

$fn = 64;

W  = pcb_width;
L  = W + arm_length;
Hc = height;                         // core height = PCB top surface
base_height = Hc - pcb_thickness;    // block height below the PCB

// Hole centers relative to the corner origin
function holes() = [
    for (y = [hole_inset, W - hole_inset]) [W + pcb_clearance + hole_inset, y],
    for (x = [hole_inset, W - hole_inset]) [x, W + pcb_clearance + hole_inset],
];

module chamfered_box(size, c) {
    hull() {
        translate([c, c, 0])        cube([size.x - 2 * c, size.y - 2 * c, size.z]);
        translate([0, 0, c])        cube([size.x, size.y, size.z - 2 * c]);
    }
}

module body() {
    chamfered_box([L, L, Hc], chamfer);
}

module pockets() {
    C = W + pcb_clearance;
    // Carrier A along +X, carrier B along +Y
    translate([C, -1, base_height]) cube([L, C + 1, Hc]);
    translate([-1, C, base_height]) cube([C + 1, L, Hc]);
    // 45 degree relief where both pockets meet the core and the inner square
    translate([C, C, base_height])
        rotate(-45)
            translate([-relief_length, -relief_width / 2, 0])
                cube([2 * relief_length, relief_width, Hc]);
}

module insert_hole() {
    translate([0, 0, base_height - insert_depth])
        cylinder(d = insert_dia, h = insert_depth + 0.01);
    translate([0, 0, base_height - insert_lead])
        cylinder(d1 = insert_dia, d2 = insert_dia + 2 * insert_lead, h = insert_lead + 0.01);
}

module magnet_pocket() {
    d = magnet_dia + magnet_clear;
    translate([W / 2, W / 2, magnet_cover > 0 ? magnet_cover : -0.01])
        cylinder(d = d, h = magnet_height + 0.2 + 0.01);
    if (magnet_cover <= 0) {
        // Entry chamfer + glue relief
        translate([W / 2, W / 2, -0.01])
            cylinder(d1 = d + 1, d2 = d, h = 0.5);
    }
}

module footprint() {
    square([L, L]);
}

module cavity() {
    difference() {
        translate([0, 0, -1])
            linear_extrude(base_height - top_plate + 1)
                offset(delta = -wall) footprint();
        for (p = holes()) translate(p) cylinder(d = insert_dia + 2 * column_wall, h = Hc);
        translate([W / 2, W / 2, 0]) cylinder(d = magnet_dia + magnet_clear + 2 * column_wall, h = Hc);
        translate([W / 2 - rib / 2, 0, 0]) cube([rib, L, Hc]);
        translate([0, W / 2 - rib / 2, 0]) cube([L, rib, Hc]);
    }
}

module corner() {
    difference() {
        body();
        cavity();
        pockets();
        for (p = holes()) translate(p) insert_hole();
        magnet_pocket();
    }
}

// Preview: four corners and four carriers forming the frame
module carrier_dummy() {
    color("darkgreen", 0.8) difference() {
        cube([pcb_length, pcb_width, pcb_thickness]);
        for (x = [hole_inset, pcb_length - hole_inset], y = [hole_inset, pcb_width - hole_inset])
            translate([x, y, -1]) cylinder(d = 3.2, h = pcb_thickness + 2);
    }
}

module assembly() {
    S = 2 * (W + pcb_clearance) + pcb_length;    // outer frame size
    for (i = [0 : 3])
        translate([S / 2, S / 2, 0]) rotate(90 * i) translate([-S / 2, -S / 2, 0]) {
            color("orange") corner();
            translate([W + pcb_clearance, 0, base_height]) carrier_dummy();
        }
}

if (part == "assembly") assembly();
else corner();
