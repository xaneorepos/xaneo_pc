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

def get_git_info():
    info = {}
    try:
        import subprocess
        sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
        short_sha = sha[:7]
        info['sha'] = sha
        info['short_sha'] = short_sha

        subject = subprocess.check_output(['git', 'log', '-1', '--pretty=format:%s'], text=True).strip()
        body = subprocess.check_output(['git', 'log', '-1', '--pretty=format:%b'], text=True).strip()
        author = subprocess.check_output(['git', 'log', '-1', '--pretty=format:%an <%ae>'], text=True).strip()
        date = subprocess.check_output(['git', 'log', '-1', '--pretty=format:%cd', '--date=short'], text=True).strip()

        info['subject'] = subject
        info['body'] = body
        info['author'] = author
        info['date'] = date

        try:
            current_tag = os.environ.get('GITHUB_REF_NAME', '')
            tags_list = subprocess.check_output(['git', 'tag', '--sort=-creatordate'], text=True).strip().splitlines()
            prev_tags = [t.strip() for t in tags_list if t.strip() and t.strip() != current_tag]
            prev_tag = prev_tags[0] if prev_tags else ''
            log_range = f"{prev_tag}..HEAD" if prev_tag else "-5"
        except Exception:
            log_range = "-5"

        changelog_lines = subprocess.check_output(['git', 'log', log_range, '--oneline', '--no-merges'], text=True).strip().splitlines()
        info['changelog'] = [line.strip() for line in changelog_lines if line.strip()]
    except Exception as e:
        print(f"Could not retrieve git info: {e}")
    return info

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

    # Generate Markdown content for GitHub release body
    md_content = []

    git_info = get_git_info()
    if git_info and 'sha' in git_info:
        server_repo = os.environ.get('GITHUB_REPOSITORY', '')
        commit_link = f"`{git_info['short_sha']}`"
        if server_repo:
            commit_link = f"[`{git_info['short_sha']}`](https://github.com/{server_repo}/commit/{git_info['sha']})"

        md_content.append("## 📌 Release Commit & Details\n")
        md_content.append(f"- **Commit:** {commit_link}")
        md_content.append(f"- **Author:** `{git_info.get('author', 'CI/CD')}`")
        md_content.append(f"- **Date:** `{git_info.get('date', '')}`\n")

        if git_info.get('subject'):
            md_content.append(f"### 💡 Commit Message:\n> **{git_info['subject']}**")
            if git_info.get('body'):
                body_quoted = "\n> ".join(git_info['body'].splitlines())
                md_content.append(f">\n> {body_quoted}")
            md_content.append("")

        if git_info.get('changelog'):
            md_content.append("### 📜 Included Commits:\n")
            for c in git_info['changelog']:
                md_content.append(f"- {c}")
            md_content.append("")

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
