import re

with open(r'd:\Antigavity\HealthPort_v1\stitch_health_gui_20260320\_3\code.html', 'r', encoding='utf-8') as f:
    html = f.read()

titles = re.findall(r'<h3 class="text-on-surface font-bold">([^<]+)</h3>', html)
features = re.findall(r'<span class="label-sm [^>]+>([^<]+)</span>', html)
images = re.findall(r'src="data:image/[^;]+;base64,([^"]+)"', html)

if len(titles) == 0 or len(images) == 0:
    print(f"Failed to find data titles={len(titles)} images={len(images)}")

code = "class StrapData {\n  static const List<Map<String, String>> straps = [\n"
for t, f, i in zip(titles, features, images):
    t = t.strip().replace("'", "\\'")
    f = f.strip().replace("'", "\\'")
    code += f"    {{'title': '{t}', 'feature': '{f}', 'image': '{i}'}},\n"
code += "  ];\n}\n"

with open(r'd:\Antigavity\HealthPort_v1\health_gui_20260324\lib\screens\strap_data.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print(f"Extracted {min(len(titles), len(features), len(images))} items out of {len(titles)} titles, {len(features)} features, {len(images)} images")
