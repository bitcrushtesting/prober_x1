// PROBER X1 - DUT Mount (PCB Holder)
//
// Hangs below the tip of a mounting arm PCB and holds the edge of the
// device under test (1.6 mm PCB) in a horizontal slit. One M3x8 thumb screw
// goes down through the arm's end hole into a heat-set thread insert.
//
// The arm is screwed under the carrier and the mount hangs under the arm, so
// the slit sits one arm thickness above the mount top: the DUT ends up at
// the same height as the carrier.
//
// Origin = arm hole center on the mount bottom. The DUT is on the -X side.

/* [Render] */
part = "mount"; // [mount, print, assembly]

/* [Heights] */
arm_thickness = 1.6;
dut_thickness = 1.6;

/* [Mounting arm] (from pcb/mounting_arm/mounting_arm.kicad_pcb) */
arm_width     = 12;
arm_tip       = 6;     // hole center to rounded arm tip

/* [Body] */
body_back     = 6;    // body length behind the hole, under the arm
tip_gap       = 0.5;   // clearance between arm tip and the jaw
chamfer       = 0.5;

/* [Jaw] */
jaw_length    = 4;
jaw_width     = 12;
top_lip       = 2;     // material above the slit
slit_depth    = 1.5;
slit_clear    = 0.2;   // added to the PCB thickness
slit_lead     = 0.2;   // entry chamfer

/* [Thread insert] */
insert_dia    = 4.0;
insert_length = 4;     // body height = insert length, hole goes through
insert_lead   = 0.4;

$fn = 64;

H      = insert_length;                            // arm bottom rests here
jaw_x  = -arm_tip - tip_gap;                       // back face of the jaw
slit_z = H + arm_thickness - slit_clear / 2;       // DUT bottom = carrier bottom = arm top
slit_h = dut_thickness + slit_clear;
jaw_h  = slit_z + slit_h + top_lip;

module chamfered_box(size, c) {
    hull() {
        translate([c, c, 0]) cube([size.x - 2 * c, size.y - 2 * c, size.z]);
        translate([0, 0, c]) cube([size.x, size.y, size.z - 2 * c]);
    }
}

module chamfered_cylinder(r, h, c) {
    hull() {
        cylinder(r = r - c, h = h);
        translate([0, 0, c]) cylinder(r = r, h = h - 2 * c);
    }
}

module body() {
    // Under the arm, fully round back
    r = arm_width / 2;
    hull() {
        // Starts at the jaw front so the bottom chamfers don't leave a notch at the joint
        translate([jaw_x - jaw_length, -r, 0]) chamfered_box([body_back - r - jaw_x + jaw_length, arm_width, H], chamfer);
        translate([body_back - r, 0, 0]) chamfered_cylinder(r, H, chamfer);
    }
    // Jaw in front of the arm tip, reaching up past the arm to the carrier plane
    translate([jaw_x - jaw_length, -jaw_width / 2, 0])
        chamfered_box([jaw_length, jaw_width, jaw_h], chamfer);
}

module slit() {
    translate([jaw_x - jaw_length - 1, -jaw_width / 2 - 1, slit_z])
        cube([slit_depth + 1, jaw_width + 2, slit_h]);
    // Lead-in chamfer at the mouth
    translate([jaw_x - jaw_length, 0, slit_z + slit_h / 2])
        rotate([90, 0, 0])
            linear_extrude(jaw_width + 2, center = true)
                polygon([[-0.01, -slit_h / 2 - slit_lead], [slit_lead, -slit_h / 2],
                         [slit_lead, slit_h / 2], [-0.01, slit_h / 2 + slit_lead]]);
}

module insert_hole() {
    translate([0, 0, -0.01])
        cylinder(d = insert_dia, h = H + 0.02);
    translate([0, 0, H - insert_lead])
        cylinder(d1 = insert_dia, d2 = insert_dia + 2 * insert_lead, h = insert_lead + 0.01);
}

module dut_mount() {
    difference() {
        body();
        slit();
        insert_hole();
    }
}

// Preview: mount with arm tip and a DUT edge
module assembly() {
    color("orange") dut_mount();
    color("darkgreen", 0.8) translate([0, 0, H]) difference() {
        hull() {
            cylinder(r = arm_tip, h = arm_thickness);
            translate([60, -arm_width / 2, 0]) cube([1, arm_width, arm_thickness]);
        }
        translate([0, 0, -1]) cylinder(d = 3.2, h = arm_thickness + 2);
    }
    color("royalblue", 0.8)
        translate([jaw_x - jaw_length + slit_depth - 0.5 - 50, -25, H + arm_thickness])
            cube([50, 50, dut_thickness]);
}

// Print standing on the jaw face: slit walls become vertical, no overhang under the lip
if (part == "assembly") assembly();
else if (part == "print") translate([0, 0, jaw_length - jaw_x]) rotate([0, -90, 0]) dut_mount();
else dut_mount();
