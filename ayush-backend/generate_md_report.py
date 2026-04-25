import json
import os

with open('db_report_dump.json', 'r') as f:
    data = json.load(f)

md_content = "# Comprehensive Database Report\n\n"
md_content += f"**User ID:** `5cf7d3fa-d479-43c3-850e-75e6485bb870`\n"
md_content += f"**Phone:** `+919110687983`\n\n"
md_content += "This report contains all data associated with the user across all collections in the MongoDB database.\n\n"

for collection, docs in data.items():
    md_content += f"## Collection: `{collection}` ({len(docs)} documents)\n"
    md_content += "```json\n"
    md_content += json.dumps(docs, indent=2)
    md_content += "\n```\n\n"

output_path = r"C:\Users\ASUS\.gemini\antigravity\brain\8ab5cb47-5723-482e-a927-5086a1281f4f\db_report.md"
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(md_content)

print(f"Generated Markdown report at {output_path}")
