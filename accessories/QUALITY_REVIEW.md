# Independent QC: experimental RAD ribbed sleeve

**Digital design score: 8/10 — suitable for controlled print-and-fit trials. Physical shelving readiness: unvalidated; no load rating.** This score concerns the accessory's CAD, customization, documented compatibility and diagnostic slicing. It does not certify printed fit, stability, TPU creep resistance or a loaded bookcase.

Reviewed final accessory SHA-256: `bf3d99dca4a91ceab847bc1660302d67f3b9213d63a27efbb1ae5fd0c490bd87`.

Reviewed upstream connector source SHA-256: `b390f26de733a5f40e937fd0eb10a3132c4ab63911c9a0de4473d734b4a4cd55`, from upstream commit `357e6d1`. The accessory is separate from that connector source.

## Evidence

- **29/29 automated geometry checks passed** in `build/validation/report.json`, using OpenSCAD 2025.09.07 with Manifold: 19 valid solids, four empty-intersection checks and six intentional parameter rejections. The valid models have one connected component, watertight and consistently wound surfaces, positive volume, finite vertices and no degenerate triangles. Cases include the native sleeve, standalone print orientation, short fit coupon, smooth comparison, several pole/rib/screw choices, the actual upstream connector and six actual JSON preset renders. The report's source hash matches the final file.
- Collision probes use the actual upstream connector. They find no sleeve/body intersection in the separately checked seated default position or at withdrawal distances 0.01, 10, 20 and 40 mm on both default side legs. These are sampled positions, not a continuous swept-volume test. The 0.01 mm first withdrawal avoids a coplanar, zero-volume contact artifact when several sleeve positions are unioned. The existing default screw cylinders have clear passages, and the sleeve clears the original stopper.
- Invalid wall space, nominal-pole/backing overlap, excessive insertion depth, teardrop scope, screw placement at the mouth and fractional rib count are rejected deliberately.
- An additional default **CGAL export** independently has one watertight, consistently wound component and zero degenerate triangles. Its volume is 5044.3936 mm³, versus 5044.3942 mm³ for Manifold. The two backends agree to export precision.
- Actual rendered views from the insertion-tip and mouth sides show a continuous backing wall, rounded broad ribs, open screw passages and a gradual mouth transition. The lip lies outside the host socket, and the upright export rests on that lip.
- PrusaSlicer 2.9.6 produced 207 extruding layers using a diagnostic 0.2 mm layer, three-perimeter, 100% rectilinear profile with supports disabled. Inspected layers at Z=0.35, 9.95, 19.55 and 21.75 mm retain the annular first layer, rib shapes, and two intended screw openings through their center and near their roofs. The subsequent Z=21.95 mm layer closes those openings. Their short local overhangs still need a physical TPU print check. This generic slicing exercise is not a calibrated TPU profile or a successful physical print.

## Geometry and integration assessment

The matched host has a 26 mm round bore, 6 mm wall, 50 mm `lengthLeg`, enabled side stops and screw centers 18 mm inward from the mouth. Its actual usable stopped side-socket depth is **44 mm**, because RAD adds wall thickness to the nominal stopper extent. The 40 mm sleeve therefore leaves 4 mm before the rigid stop. Native screw angle zero correctly points along local -Y; manual rotational alignment is required.

The default sleeve outside diameter is 25.8 mm; its continuous backing bore is 23.4 mm and its unloaded rib-tip bore is 19.7 mm for a nominal 20 mm pole. The rounded ribs provide the intended local interference. Parameter guards now require at least 0.2 mm radial relief between the nominal pole and backing wall, and at least 1 mm separation between screw openings measured at the backing wall's inner radius. These guards prevent two misleading customization cases that the initial version allowed.

The CAD fit clearance is small: RAD's 50-sided nominal 26 mm bore has about 25.9487 mm minimum across-flat diameter. The default sleeve has only about **0.074 mm minimum radial geometric clearance**. A fit coupon and measured printed dimensions are therefore necessary; this result is not a guarantee of a freely sliding printed fit.

The short coupon, smooth comparison mode, readable parameter groups, explicit units, matched host preset and importable module make the accessory usable for iterative trials. Its supported scope is appropriately narrow: the matched round side sockets. Other RAD connector types, unusual leg angles, teardrop bores and different fasteners need separate checks.

## Iteration findings resolved

1. The initial bore polyhedron winding was corrected; the final meshes are valid in both tested backends.
2. The screw-opening separation check was strengthened from the sleeve outer radius to the backing wall's inner radius.
3. A nominal pole that overlapped the continuous backing wall could initially pass the rib-height check; the final relief guard rejects it.
4. Loft side quads were replaced by explicit triangles, removing the CGAL nonplanar-face fallback. Final meshes, presets, views and diagnostic slicing were regenerated after that change.

## Remaining physical evidence

The original screws provide fastening; the sleeve introduces compliance and does not establish reliable retention by friction. No print, insertion-force, repeated-assembly, screw-engagement, joint-stiffness, creep or shelf-load test has been completed. A snug feel is not a stability measurement. Hollow bamboo and irregular or oval poles need actual tests, and a frame with many joints needs bracing and its own displacement and sustained-load evaluation.

No digital-design blocker remains for the stated scope. The accessory is reasonable to contribute as an **experimental, digitally checked prototype** with these limits. It is not yet supported by evidence for a claim of tested furniture performance. The documented physical evaluation sequence should determine subsequent fit and material revisions before stronger claims or a production-oriented PR.
