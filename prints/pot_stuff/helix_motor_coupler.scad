// =====================================================
// Helical Pot Coupler — motor flange to pot shaft
// Units: mm
// =====================================================

// ---- Pot side ----
pot_shaft_d     = 6.35;     // 1/4" round bore
pot_hub_len     = 6;
pot_hub_od      = 10;
//pot_setscrew_d  = 3.4;

// ---- Helix ----
helix_height    = 35;
helix_turns     = 3;
ribbon_thk      = 6;
ribbon_height   = 6;

// ---- Motor flange ----
flange_d        = 100;
flange_h        = 3;
bolt_hole_d     = 5.105;    // 1/4-20 tap drill
bolt_circle_r   = 42;       // radius from center to each hole
num_bolts       = 8;
sma_clearance_d = 14.0;     // center bore for SMA

$fn = 96;

// ---- Derived ----
// Helix tapers from near flange edge to pot hub OD
helix_r_start = bolt_circle_r - ribbon_thk - 2;
helix_r_end   = pot_hub_od/2 + 1.5;

// =====================================================
module tapered_helical_ribbon(length, turns, r_start, r_end,
                               r_thk, h_tape, steps_per_turn=120) {
    steps = max(8, ceil(steps_per_turn * turns));
    dz    = length / steps;
    dA    = 360 * turns / steps;
    dr    = (r_end - r_start) / steps;
    for (i = [0 : steps - 1]) {
        a0 = i * dA;
        z0 = i * dz;
        r0 = r_start + i * dr;
        a1 = (i+1) * dA;
        z1 = (i+1) * dz;
        r1 = r_start + (i+1) * dr;
        hull() {
            translate([r0*cos(a0), r0*sin(a0), z0])
                rotate([0, 0, a0])
                cube([r_thk, 0.6, h_tape], center = true);
            translate([r1*cos(a1), r1*sin(a1), z1])
                rotate([0, 0, a1])
                cube([r_thk, 0.6, h_tape], center = true);
        }
    }
}

module pot_hub() {
    difference() {
        cylinder(h = pot_hub_len, d = pot_hub_od);
        translate([0, 0, -0.1])
            cylinder(h = pot_hub_len + 0.2, d = pot_shaft_d + 0.1);
        translate([0, 0, pot_hub_len / 2])
            rotate([0, 90, 0]);
            //cylinder(h = pot_hub_od, d = pot_setscrew_d);
    }
}

module motor_flange() {
    difference() {
        cylinder(h = flange_h, d = flange_d);
        // center SMA bore
        translate([0, 0, -0.1])
            cylinder(h = flange_h + 0.2, d = sma_clearance_d);
        // 8 bolt holes on bolt circle
        for (i = [0 : num_bolts - 1]) {
            a = i * 360 / num_bolts;
            rotate([0, 0, a])
            translate([bolt_circle_r, 0, -0.1])
                cylinder(h = flange_h + 0.2, d = bolt_hole_d);
        }
    }
}

// ring that joins the helix to the pot hub outer wall
module helix_to_pot_ring() {
    ring_h = ribbon_height;
    difference() {
        cylinder(h = ring_h, d = 2 * helix_r_end + ribbon_thk + 1);
        translate([0, 0, -0.1])
            cylinder(h = ring_h + 0.2, d = pot_hub_od - 0.1);
    }
}

// =====================================================
// Full assembly — single part
// =====================================================

// motor flange at the bottom
motor_flange();

// helix starts at top of flange, offset up by half ribbon height
// so nothing protrudes below flange top
helix_z0 = flange_h;

translate([0, 0, helix_z0])
    tapered_helical_ribbon(helix_height, helix_turns,
                           helix_r_start, helix_r_end,
                           ribbon_thk, ribbon_height);

// connecting ring at top of helix, wraps around pot hub
ring_z = helix_z0 + helix_height - ribbon_height/2;
translate([0, 0, ring_z])
    helix_to_pot_ring();

// pot hub rises from inside the ring
translate([0, 0, ring_z])
    pot_hub();