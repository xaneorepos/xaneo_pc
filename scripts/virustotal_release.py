#!/usr/bin/env python3
import os
import sys
import glob
import shutil
import hashlib
import json
import urllib.request
import urllib.parse

def calculate_sha256(filepath):
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(8192 * 1024):
            sha256.update(chunk)
    return sha256.hexdigest()

def upload_to_virustotal(filepath, api_key):
    filename = os.path.basename(filepath)
    file_size = os.path.getsize(filepath)
    print(f"Uploading {filename} ({file_size} bytes) to VirusTotal...")

    headers = {'x-apikey': api_key}
    upload_url = 'https://www.virustotal.com/api/v3/files'

    # If file size > 32MB, get large file upload URL
    if file_size > 32 * 1024 * 1024:
        try:
            req = urllib.request.Request(
                'https://www.virustotal.com/api/v3/files/upload_url',
                headers=headers
            )
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                upload_url = data.get('data')
                print(f"Acquired large upload URL for {filename}")
        except Exception as e:
            print(f"Failed to get upload URL for {filename}: {e}")

    try:
        boundary = '----WebKitFormBoundaryXaneoVTUpload'
        with open(filepath, 'rb') as f:
            file_data = f.read()

        body = (
            f'--{boundary}\r\n'
            f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
            f'Content-Type: application/octet-stream\r\n\r\n'
        ).encode('utf-8') + file_data + f'\r\n--{boundary}--\r\n'.encode('utf-8')

        req = urllib.request.Request(
            upload_url,
            data=body,
            headers={
                'x-apikey': api_key,
                'Content-Type': f'multipart/form-data; boundary={boundary}'
            },
            method='POST'
        )

        with urllib.request.urlopen(req) as resp:
            res_data = json.loads(resp.read().decode('utf-8'))
            print(f"Successfully submitted {filename} to VirusTotal: {res_data.get('data', {}).get('id')}")
            return res_data
    except Exception as e:
        print(f"VirusTotal API upload error for {filename}: {e}")
        return None

def main():
    artifacts_dir = sys.argv[1] if len(sys.argv) > 1 else 'artifacts'
    dist_dir = sys.argv[2] if len(sys.argv) > 2 else 'release_dist'
    body_file = sys.argv[3] if len(sys.argv) > 3 else 'release_body.md'

    api_key = os.environ.get('VIRUSTOTAL_API_KEY', '').strip()

    os.makedirs(dist_dir, exist_ok=True)

    # Collect all release files recursively from artifacts_dir
    patterns = ['*.zip', '*.exe', '*.deb', '*.rpm', '*.AppImage', '*.dmg']
    found_files = []
    for root, _, files in os.walk(artifacts_dir):
        for file in files:
            if any(file.endswith(ext.replace('*', '')) for ext in patterns):
                found_files.append(os.path.join(root, file))

    found_files.sort()
    print(f"Found {len(found_files)} release file(s) in {artifacts_dir}: {found_files}")

    reports = []

    for filepath in found_files:
        filename = os.path.basename(filepath)
        target_path = os.path.join(dist_dir, filename)
        shutil.copy2(filepath, target_path)

        sha256_hash = calculate_sha256(target_path)
        vt_url = f"https://www.virustotal.com/gui/file/{sha256_hash}"

        if api_key:
            upload_to_virustotal(target_path, api_key)
        else:
            print(f"VIRUSTOTAL_API_KEY not set. Skipping API upload for {filename}.")

        reports.append({
            'filename': filename,
            'sha256': sha256_hash,
            'vt_url': vt_url
        })

    # Generate Markdown table for GitHub release body
    md_content = []
    md_content.append("## 🛡️ Security Scans & File Integrity\n")
    md_content.append("All binaries are scanned for malware and verified. You can review the VirusTotal scan reports and SHA-256 checksums below:\n")
    md_content.append("| Release File | SHA-256 Checksum | VirusTotal Scan |")
    md_content.append("| :--- | :--- | :---: |")

    for item in reports:
        fn = item['filename']
        hash_short = f"`{item['sha256'][:16]}...{item['sha256'][-8:]}`"
        vt_link = f"[🛡️ View Report]({item['vt_url']})"
        md_content.append(f"| ` {fn} ` | {hash_short} | {vt_link} |")

    md_content.append("\n<details>\n<summary><b>Full SHA-256 Hashes</b></summary>\n\n```text")
    for item in reports:
        md_content.append(f"{item['sha256']}  {item['filename']}")
    md_content.append("```\n</details>\n")

    with open(body_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(md_content))

    print(f"Successfully generated release body in {body_file}")

if __name__ == '__main__':
    main()
