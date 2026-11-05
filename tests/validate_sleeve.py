"""Digital geometry checks only; no claims about physical fit or shelf loads.

Requires OpenSCAD CLI, numpy and trimesh. Example:
python tests/validate_sleeve.py --openscad /path/to/openscad
Outputs remain in ignored build/validation. A nonzero exit indicates failure.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build' / 'validation'
SOURCE = ROOT / 'accessories' / 'Ribbed Sleeve.scad'
HOST = ROOT / 'Rod Assisted Design Customizer.scad'


def scad_value(value):
    return json.dumps(value, separators=(',', ':'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--openscad', default='openscad')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    version = subprocess.run([args.openscad, '--version'], capture_output=True, text=True)

    def run(case):
        name, settings, expected = case
        wrapper = OUT / (name + '.scad')
        mesh_path = OUT / (name + '.stl')
        # Every run starts clean: stale outputs cannot turn a failed render into a pass.
        mesh_path.unlink(missing_ok=True)
        if isinstance(settings, str):
            source = settings
        elif isinstance(settings, tuple):
            source = None
        else:
            params = ','.join(f'{key}={scad_value(value)}' for key, value in settings.items())
            source = f'use <{SOURCE.as_posix()}>\nribbed_sleeve({params});\n'
        if source is not None:
            wrapper.write_text(source, encoding='utf-8')
            input_args = [str(wrapper)]
        else:
            model, presets, preset_name = settings
            input_args = ['-p', str(presets), '-P', preset_name, str(model)]
        process = subprocess.run([args.openscad, '--backend=Manifold', '-o', str(mesh_path)] + input_args,
                                 capture_output=True, text=True, timeout=180)
        log = process.stdout + process.stderr
        (OUT / (name + '.log')).write_text(log, encoding='utf-8')
        result = dict(name=name, expectation=expected, returncode=process.returncode)
        if expected == 'rejected':
            result['passed'] = 'Assertion' in log and 'ERROR:' in log and not mesh_path.exists()
        elif expected == 'empty':
            result['passed'] = ('Current top level object is empty' in log and not mesh_path.exists()
                                and 'ERROR:' not in log and 'WARNING:' not in log)
        else:
            if process.returncode or not mesh_path.exists() or 'ERROR:' in log or 'WARNING:' in log:
                result.update(passed=False, error=log[-2000:])
            else:
                mesh = trimesh.load_mesh(mesh_path)
                components = mesh.split(only_watertight=False)
                result.update(watertight=bool(mesh.is_watertight),
                              winding_consistent=bool(mesh.is_winding_consistent),
                              components=len(components), volume_mm3=round(float(mesh.volume), 4),
                              bounds_mm=np.round(mesh.bounds, 5).tolist(), triangles=len(mesh.faces),
                              degenerate_triangles=int(np.count_nonzero(mesh.area_faces < 1e-10)))
                result['passed'] = bool(mesh.is_watertight and mesh.is_winding_consistent
                                        and len(components) == 1 and mesh.volume > 0
                                        and np.isfinite(mesh.vertices).all()
                                        and result['degenerate_triangles'] == 0)
                if name in ('print_orientation', 'fit_coupon'):
                    expected_top = 41.6 if name == 'print_orientation' else 13.6
                    result['on_bed_and_correct_height'] = bool(np.allclose(mesh.bounds[:,2], [0,expected_top], atol=1e-5))
                    result['passed'] = result['passed'] and result['on_bed_and_correct_height']
        print(json.dumps(result), flush=True)
        return result

    cases = [
        ('default', {}, 'solid'),
        ('print_orientation', f'include <{SOURCE.as_posix()}>\n', 'solid'),
        ('fit_coupon', f'include <{SOURCE.as_posix()}>\noutput_mode="fit_coupon";\n', 'solid'),
        ('smooth_baseline', {'rib_count':0}, 'solid'),
        ('pole_19', {'pole_diameter':19}, 'solid'),
        ('pole_21', {'pole_diameter':21}, 'solid'),
        ('six_ribs', {'rib_count':6}, 'solid'),
        ('ten_ribs', {'rib_count':10}, 'solid'),
        ('single_screw', {'screw_angles':[90]}, 'solid'),
        ('no_screws', {'screw_angles':[]}, 'solid'),
        ('four_screws', {'screw_angles':[0,90,180,270]}, 'solid'),
        ('large_socket', {'socket_bore_diameter':30, 'pole_diameter':24}, 'solid'),
        ('insufficient_wall', {'wall_thickness':4}, 'rejected'),
        ('backing_wall_interference', {'pole_diameter':23.6}, 'rejected'),
        ('too_deep_for_stop', {'insertion_length':48}, 'rejected'),
        ('teardrop_not_supported', {'rad_teardrop_enabled':True}, 'rejected'),
        ('screw_at_mouth', {'screw_distance_from_mouth':0}, 'rejected'),
        ('fractional_rib_count', {'rib_count':6.5}, 'rejected'),
    ]
    # Include the actual upstream generator, suppress its top-level output with type=0.
    # The model is unchanged; the explicit supported preset disables teardrops.
    prefix = (f'include <{HOST.as_posix()}>\nuse <{SOURCE.as_posix()}>\n'
              'type=0; teardropEnable=0;\n'
              'module placed_sleeve() { rotate([90,0,135]) translate([0,0,69]) ribbed_sleeve(); }\n')
    cases += [
        ('actual_connector', prefix + 'connector();', 'solid'),
        ('host_sleeve_collision', prefix + 'intersection(){ connector(); placed_sleeve(); }', 'empty'),
        ('insertion_path_collision', prefix +
         'intersection(){ connector(); for(a=[135,225],t=[0.01,10,20,40]) rotate([90,0,a]) '
         'translate([0,0,69+t]) ribbed_sleeve(); }', 'empty'),
        ('screw_passages', f'use <{SOURCE.as_posix()}>\nintersection(){{ribbed_sleeve();'
         'union(){for(a=[0,180]) translate([0,0,-18]) rotate([90,0,a]) cylinder(d=4,h=20,$fn=50);}}', 'empty'),
        ('stop_clearance', f'use <{SOURCE.as_posix()}>\nintersection(){{ribbed_sleeve();'
         'translate([-20,-20,-50])cube([40,40,6]);}', 'empty'),
    ]
    for model in (HOST, SOURCE):
        presets = model.with_suffix('.json')
        for index, preset_name in enumerate(json.loads(presets.read_text())['parameterSets']):
            cases.append((f'preset_{"host" if model == HOST else "sleeve"}_{index}',
                          (model, presets, preset_name), 'solid'))
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(run, cases))
    report = dict(openscad=(version.stdout+version.stderr).strip(),
                  source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                  upstream_source_sha256=hashlib.sha256(HOST.read_bytes()).hexdigest(),
                  scope='Geometry only; no physical fit, print, creep or load validation',
                  passed=all(r['passed'] for r in results), cases=results)
    (OUT / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
