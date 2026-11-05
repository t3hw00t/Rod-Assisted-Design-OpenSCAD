# Sleeve geometry regression checks

Install Python packages `numpy` and `trimesh`, and an OpenSCAD build supporting
the `--backend=Manifold` switch. From the repository root, run:

```text
python tests/validate_sleeve.py --openscad /path/to/openscad
```

The script writes meshes, logs and `report.json` into ignored `build/validation`.
It returns nonzero if a check fails. It checks mesh topology, invalid parameter
rejection, print orientation, the actual JSON presets, screw passages, stopper
clearance, and intersections with the actual upstream connector generator.

The default sleeve is tested in its exactly seated position. The insertion-path
probe samples both default side sockets at 0.01, 10, 20 and 40 mm outward from
the mouth. The 0.01 mm sample excludes intentional coplanar lip/end-face contact;
it is not a change to the seated fit. This is a sampled path test, not continuous
collision detection or a deformation/contact simulation.

The default mesh should also be exported with CGAL to check backend compatibility:

```text
openscad --backend=CGAL --hardwarnings -o build/sleeve-cgal.stl "accessories/Ribbed Sleeve.scad"
```

An optional diagnostic slice (not a printer/TPU profile) can be reproduced with:

```text
prusa-slicer --layer-height 0.2 --perimeters 3 --fill-density 100% --fill-pattern rectilinear --no-support-material --export-gcode --output build/sleeve-diagnostic.gcode build/validation/print_orientation.stl
```

Successful geometry or slicing does not validate TPU fit, hole bridging,
fastening, creep, bending stiffness or shelf capacity. Physical checks are listed
in [the accessory guide](../accessories/README.md).
