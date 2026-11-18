// PROBER X1 - Assembly
//
// Complete prober: four corners, four carriers, four mounting arms with DUT
// mounts and an example DUT. The PCB meshes in pcb/ are exported from the
// KiCad projects by render.sh, which also renders the images in docs/img.
//
// Origin = outer corner of the frame on the base plate.

use <corner.scad>
use <dut_mount.scad>

/* [Render] */
view = "full"; // [full, dut_mount]

/* [Example DUT] */
dut_size      = [80, 60];  // held by the arms on X and Y
dut_thickness = 1.6;

/* [Arm position] */
arm_hole_x    = 77.5;  // carrier hole the arm is screwed to, from the carrier end

// From corner.scad / dut_mount.scad / the KiCad projects
pcb_length    = 130;
pcb_width     = 40;
pcb_thickness = 1.6;
pcb_clearance = 0.2;
corner_height = 40;
hole_inset    = 7.5;
carrier_hole_y = 28;    // arm holes, from the outer carrier edge
arm_thickness = 1.6;
insert_length = 4;      // DUT mount body height
dut_edge      = 9;      // slit bottom, from the DUT mount hole

W  = pcb_width + pcb_clearance;
S  = 2 * W + pcb_length;               // outer frame size
Z  = corner_height - pcb_thickness;    // carrier bottom = DUT bottom
Za = Z - arm_thickness;                // arm bottom

c_print   = "#f28c28";
c_pcb     = "#1f6f43";
c_parts   = "#303030";
c_dut     = "#3b4cc0";
c_pad     = "#d4a017";
c_steel   = "#b8b8b8";

$fn = 48;

module carrier() {
    color(c_parts) import("pcb/carrier.stl");
    // Board over the combined mesh so it shows in PCB green
    color(c_pcb) translate([-0.01, -0.01, -0.01]) scale([1, 1, 1.02])
        resize([pcb_length + 0.02, pcb_width + 0.02, 0]) import("pcb/carrier_board.stl");
}

module arm() {
    color(c_pcb) import("pcb/mounting_arm.stl");
}

module button_screw() {
    color(c_steel) {
        translate([0, 0, 0]) scale([1, 1, 0.55]) sphere(d = 5.7);
        translate([0, 0, -8]) cylinder(d = 3, h = 8);
    }
}

module thumb_screw(h) {
    color(c_steel) {
        cylinder(d = 10, h = 3, $fn = 30);
        translate([0, 0, 3]) cylinder(d = 6, h = 2);
        translate([0, 0, -h]) cylinder(d = 3, h = h);
    }
}

module nut() {
    color(c_steel) difference() {
        union() {
            cylinder(d = 6.4, h = 2.4, $fn = 6);
            cylinder(d = 8, h = 0.6);
        }
        translate([0, 0, -1]) cylinder(d = 3, h = 5);
    }
}

// Distance from the arm end hole to the carrier screw for a DUT edge at d
// from the frame center
function arm_slot(d) = S / 2 - d - dut_edge - carrier_hole_y;

// One side of the frame: corner at the origin, carrier along +X, arm holding
// the DUT edge at distance d from the frame center
module side(d) {
    color(c_print) corner();
    translate([W, 0, Z]) carrier();
    // Corner screws
    for (x = [hole_inset, pcb_length - hole_inset], y = [hole_inset, pcb_width - hole_inset])
        if (x < W) translate([W + x, y, corner_height]) button_screw();
    for (x = [hole_inset, pcb_width - hole_inset])
        translate([x, W + hole_inset, corner_height]) button_screw();

    s  = arm_slot(d);
    hx = W + arm_hole_x;
    hy = carrier_hole_y + s;
    // Arm under the carrier, end hole pointing to the frame center
    translate([hx, hy, Za]) rotate(-90) {
        arm();
        // DUT mount under the arm tip
        translate([0, 0, -insert_length]) color(c_print) dut_mount();
        translate([0, 0, arm_thickness]) thumb_screw(8);
    }
    // Arm screw through the carrier and the slot
    translate([hx, carrier_hole_y, corner_height]) thumb_screw(16);
    translate([hx, carrier_hole_y, Za]) mirror([0, 0, 1]) nut();
}

module dut() {
    translate([S / 2 - dut_size.x / 2, S / 2 - dut_size.y / 2, Z]) {
        color(c_dut) cube([dut_size.x, dut_size.y, dut_thickness]);
        // Test points on both sides
        color(c_pad) for (i = [0 : 5], j = [0 : 3], z = [-0.03, dut_thickness])
            translate([12 + i * 11, 12 + j * 12, z]) cylinder(d = 2, h = 0.05);
        // A few parts on top
        color(c_parts) {
            translate([30, 22, dut_thickness]) cube([18, 14, 2]);
            translate([12, 40, dut_thickness]) cube([8, 5, 1.2]);
            translate([58, 16, dut_thickness]) cube([10, 10, 1.5]);
        }
    }
}

module assembly() {
    // Carriers at 0 and 180 deg hold the DUT's Y edges, the others its X edges
    for (i = [0 : 3])
        translate([S / 2, S / 2, 0]) rotate(90 * i) translate([-S / 2, -S / 2, 0])
            side(i % 2 == 0 ? dut_size.y / 2 : dut_size.x / 2);
    dut();
}

if (view == "dut_mount") {
    // DUT mount at the bottom arm tip, origin = arm end hole
    s = arm_slot(dut_size.y / 2);
    translate(-[W + arm_hole_x, carrier_hole_y + s, Za])
        intersection() {
            assembly();
            translate([W + arm_hole_x - 22, carrier_hole_y - 8, 0]) cube([44, s + 30, 46]);
        }
} else {
    assembly();
}
