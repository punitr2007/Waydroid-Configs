#!/usr/bin/env python3
"""
Fast Multi-Threaded Waydroid Image Downloader & Installer
Bypasses slow single-stream SourceForge downloads using multi-connection HTTP range chunking against resolved direct mirrors.
"""

import os
import sys
import json
import time
import shutil
import hashlib
import argparse
import subprocess
import zipfile
import threading
import concurrent.futures
from urllib.request import Request, urlopen

OTA_SYSTEM_URL = "https://ota.waydro.id/system/lineage/waydroid_x86_64/{type}.json"
OTA_VENDOR_URL = "https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json"

def fetch_json(url):
    req = Request(url, headers={"User-Agent": "curl/8.0"})
    with urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def resolve_direct_mirror_url(url):
    """
    Resolves SourceForge redirect chain to get the direct mirror URL (e.g. *.dl.sourceforge.net)
    which supports HTTP 206 Partial Content / Range requests.
    """
    target_url = url
    if "sourceforge.net/projects/" in url and "/files/" in url:
        path = url.split("/files/")[1]
        if path.endswith("/download"):
            path = path[:-9]
        target_url = f"https://downloads.sourceforge.net/project/waydroid/{path}"

    cmd = ["curl", "-sI", target_url]
    res = subprocess.run(cmd, capture_output=True, text=True)
    
    for line in res.stdout.splitlines():
        if line.lower().startswith("location:"):
            direct = line.split(":", 1)[1].strip()
            if "dl.sourceforge.net" in direct or "viasf=1" in direct:
                return direct

    # Direct mirror fallback
    if "sourceforge.net" in url and "/files/" in url:
        path = url.split("/files/")[1].replace("/download", "")
        return f"https://excellmedia.dl.sourceforge.net/project/waydroid/{path}"
        
    return url

def download_chunk(url, start_byte, end_byte, output_path, chunk_idx, progress_dict, lock):
    expected_size = end_byte - start_byte + 1
    
    if os.path.exists(output_path) and os.path.getsize(output_path) == expected_size:
        with lock:
            progress_dict[chunk_idx] = expected_size
        return output_path

    cmd = [
        "curl", "-sSL",
        "-r", f"{start_byte}-{end_byte}",
        "-o", output_path,
        url
    ]
    
    proc = subprocess.Popen(cmd)
    while proc.poll() is None:
        time.sleep(0.2)
        if os.path.exists(output_path):
            curr_size = os.path.getsize(output_path)
            with lock:
                progress_dict[chunk_idx] = min(curr_size, expected_size)

    if proc.returncode != 0:
        raise RuntimeError(f"Chunk {chunk_idx} ({start_byte}-{end_byte}) failed with exit code {proc.returncode}")

    actual_size = os.path.getsize(output_path)
    if actual_size != expected_size:
        raise RuntimeError(f"Chunk {chunk_idx} size mismatch: got {actual_size} bytes, expected {expected_size} bytes")

    if chunk_idx == 0:
        with open(output_path, "rb") as f:
            magic = f.read(4)
            if not magic.startswith(b"PK"):
                raise RuntimeError(f"Server returned non-zip content (header: {magic}). Mirror may be rejecting range requests.")

    with lock:
        progress_dict[chunk_idx] = expected_size
    return output_path

def download_file_multithreaded(url, output_file, total_size, threads=12, label="Downloading"):
    print(f"\n[*] Resolving high-speed direct mirror for {label}...")
    direct_url = resolve_direct_mirror_url(url)
    print(f"    Mirror Direct Endpoint: {direct_url.split('?')[0]}")

    print(f"\n[+] {label}: {os.path.basename(output_file)}")
    print(f"    Total size: {total_size / (1024*1024):.2f} MB | Parallel threads: {threads}")

    temp_dir = output_file + ".parts"
    os.makedirs(temp_dir, exist_ok=True)

    chunk_size = total_size // threads
    ranges = []
    for i in range(threads):
        start = i * chunk_size
        end = total_size - 1 if i == threads - 1 else (i + 1) * chunk_size - 1
        part_file = os.path.join(temp_dir, f"part_{i}.bin")
        ranges.append((start, end, part_file, i))

    progress_dict = {i: 0 for i in range(threads)}
    lock = threading.Lock()
    start_time = time.time()
    
    for start, end, part_file, i in ranges:
        if os.path.exists(part_file):
            expected = end - start + 1
            if os.path.getsize(part_file) == expected:
                progress_dict[i] = expected

    stop_event = threading.Event()
    def reporter():
        while not stop_event.is_set():
            with lock:
                current_bytes = sum(progress_dict.values())
            pct = (current_bytes / total_size) * 100 if total_size > 0 else 0
            elapsed = time.time() - start_time
            speed_mb = (current_bytes / (1024 * 1024)) / elapsed if elapsed > 0 else 0
            eta = (total_size - current_bytes) / (speed_mb * 1024 * 1024) if speed_mb > 0 else 0
            
            bar_len = 30
            filled = int(bar_len * pct / 100)
            bar = "█" * filled + "░" * (bar_len - filled)
            
            sys.stdout.write(
                f"\r    [{bar}] {pct:5.1f}% | "
                f"{current_bytes/(1024*1024):.1f}/{total_size/(1024*1024):.1f} MB | "
                f"{speed_mb:5.1f} MB/s | ETA: {int(eta)}s "
            )
            sys.stdout.flush()
            time.sleep(0.25)

    rep_thread = threading.Thread(target=reporter, daemon=True)
    rep_thread.start()

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
            futures = [
                executor.submit(download_chunk, direct_url, start, end, part_file, i, progress_dict, lock)
                for start, end, part_file, i in ranges
            ]
            for f in concurrent.futures.as_completed(futures):
                f.result()
    finally:
        stop_event.set()
        rep_thread.join()

    total_elapsed = time.time() - start_time
    avg_speed = (total_size / (1024*1024)) / total_elapsed if total_elapsed > 0 else 0
    bar = "█" * 30
    print(f"\r    [{bar}] 100.0% | {total_size/(1024*1024):.1f}/{total_size/(1024*1024):.1f} MB | Avg: {avg_speed:.1f} MB/s in {total_elapsed:.1f}s")

    print("    -> Merging chunk files into target archive...")
    with open(output_file, "wb") as outfile:
        for _, _, part_file, _ in ranges:
            with open(part_file, "rb") as pf:
                shutil.copyfileobj(pf, outfile, length=1024*1024*8)

    shutil.rmtree(temp_dir)
    print(f"    ✓ Download completed successfully: {output_file}")

def verify_checksum(filepath, expected_sha256):
    print(f"\n[+] Verifying SHA256 checksum for {os.path.basename(filepath)}...")
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4 * 1024 * 1024), b""):
            sha256_hash.update(byte_block)
    computed = sha256_hash.hexdigest()
    if computed.lower() == expected_sha256.lower():
        print(f"    ✓ Checksum verified! ({computed[:16]}...)")
        return True
    else:
        print(f"    ✗ Checksum mismatch!")
        print(f"      Computed: {computed}")
        print(f"      Expected: {expected_sha256}")
        return False

def extract_image(zip_path, target_img_name, output_dir):
    print(f"\n[+] Extracting {target_img_name} from {os.path.basename(zip_path)}...")
    os.makedirs(output_dir, exist_ok=True)
    with zipfile.ZipFile(zip_path, 'r') as z:
        found = False
        for filename in z.namelist():
            if filename.endswith(".img") or filename == target_img_name:
                print(f"    Extracting {filename} -> {os.path.join(output_dir, target_img_name)}")
                with z.open(filename) as source, open(os.path.join(output_dir, target_img_name), "wb") as target:
                    shutil.copyfileobj(source, target, length=8*1024*1024)
                found = True
                break
        if not found:
            raise FileNotFoundError(f"Could not locate image file inside {zip_path}")
    print(f"    ✓ Extracted {target_img_name} ({os.path.getsize(os.path.join(output_dir, target_img_name)) / (1024*1024):.1f} MB)")

def install_and_init(images_dir):
    """
    Waydroid checks /etc/waydroid-extra/images or /usr/share/waydroid-extra/images
    for preinstalled images. Symlinking our images there ensures Waydroid skips downloading!
    """
    print("\n[*] Registering local images with Waydroid...")
    system_img = os.path.join(images_dir, "system.img")
    vendor_img = os.path.join(images_dir, "vendor.img")

    if not os.path.exists(system_img) or not os.path.exists(vendor_img):
        print("[!] Missing system.img or vendor.img in images directory!")
        return

    extra_dir = "/etc/waydroid-extra/images"
    print(f"[*] Linking images to {extra_dir} so Waydroid uses local files without downloading...")
    subprocess.run(["sudo", "mkdir", "-p", extra_dir], check=True)
    subprocess.run(["sudo", "ln", "-sf", system_img, f"{extra_dir}/system.img"], check=True)
    subprocess.run(["sudo", "ln", "-sf", vendor_img, f"{extra_dir}/vendor.img"], check=True)

    print("\n[*] Initializing Waydroid (sudo waydroid init -f)...")
    subprocess.run(["sudo", "waydroid", "init", "-f"], check=True)

    print("\n[*] Enabling and starting waydroid-container service...")
    subprocess.run(["sudo", "systemctl", "enable", "--now", "waydroid-container"])
    print("\n✓ Waydroid initialization completed successfully!")

def main():
    parser = argparse.ArgumentParser(description="Fast Multi-Threaded Waydroid Image Downloader")
    parser.add_argument("--type", choices=["GAPPS", "VANILLA"], default="GAPPS",
                        help="Choose between GAPPS (Google Play) or VANILLA (Pure AOSP/LineageOS)")
    parser.add_argument("--threads", type=int, default=12,
                        help="Number of concurrent download connections (default: 12)")
    parser.add_argument("--out-dir", default="./images",
                        help="Directory to save extracted system.img and vendor.img (default: ./images)")
    parser.add_argument("--init", action="store_true",
                        help="Automatically register local images and run 'sudo waydroid init -f'")
    parser.add_argument("--keep-zips", action="store_true",
                        help="Keep the downloaded .zip archives after extraction")

    args = parser.parse_args()

    work_dir = os.path.dirname(os.path.abspath(__file__))
    download_dir = os.path.join(work_dir, "downloads")
    images_dir = os.path.abspath(args.out_dir)
    
    os.makedirs(download_dir, exist_ok=True)
    os.makedirs(images_dir, exist_ok=True)

    system_img = os.path.join(images_dir, "system.img")
    vendor_img = os.path.join(images_dir, "vendor.img")

    # If images already exist and user just wants init
    if os.path.exists(system_img) and os.path.exists(vendor_img) and args.init:
        print("[+] Found already extracted system.img and vendor.img in images directory!")
        install_and_init(images_dir)
        return

    print("=" * 70)
    print(f"  Waydroid Fast Downloader (Target: {args.type} | Arch: x86_64)")
    print(f"  Images Directory: {images_dir}")
    print("=" * 70)

    # 1. Fetch System Image Metadata
    print("\n[*] Fetching latest OTA metadata from https://ota.waydro.id ...")
    try:
        sys_ota = fetch_json(OTA_SYSTEM_URL.format(type=args.type))
        latest_sys = sys_ota["response"][0]
    except Exception as e:
        print(f"[!] Error fetching system metadata: {e}")
        sys.exit(1)

    # 2. Fetch Vendor Image Metadata
    try:
        vendor_ota = fetch_json(OTA_VENDOR_URL)
        latest_vendor = vendor_ota["response"][0]
    except Exception as e:
        print(f"[!] Error fetching vendor metadata: {e}")
        sys.exit(1)

    print(f"[+] Latest System ({args.type}): {latest_sys['filename']} ({latest_sys['size']/(1024*1024):.1f} MB)")
    print(f"[+] Latest Vendor: {latest_vendor['filename']} ({latest_vendor['size']/(1024*1024):.1f} MB)")

    sys_zip_path = os.path.join(download_dir, latest_sys["filename"])
    vendor_zip_path = os.path.join(download_dir, latest_vendor["filename"])

    # Clean up any partial or corrupt files
    if os.path.exists(sys_zip_path) and os.path.getsize(sys_zip_path) != latest_sys["size"]:
        os.remove(sys_zip_path)
    if os.path.exists(vendor_zip_path) and os.path.getsize(vendor_zip_path) != latest_vendor["size"]:
        os.remove(vendor_zip_path)

    # Download System
    download_file_multithreaded(
        url=latest_sys["url"],
        output_file=sys_zip_path,
        total_size=latest_sys["size"],
        threads=args.threads,
        label=f"System Image ({args.type})"
    )
    if not verify_checksum(sys_zip_path, latest_sys["id"]):
        print("[!] System image checksum failed. Aborting extraction.")
        sys.exit(1)

    # Download Vendor
    download_file_multithreaded(
        url=latest_vendor["url"],
        output_file=vendor_zip_path,
        total_size=latest_vendor["size"],
        threads=args.threads,
        label="Vendor Image (Mainline)"
    )
    if not verify_checksum(vendor_zip_path, latest_vendor["id"]):
        print("[!] Vendor image checksum failed. Aborting extraction.")
        sys.exit(1)

    # Extract images
    extract_image(sys_zip_path, "system.img", images_dir)
    extract_image(vendor_zip_path, "vendor.img", images_dir)

    if not args.keep_zips:
        print("\n[*] Cleaning up zip archives to save disk space...")
        try:
            os.remove(sys_zip_path)
            os.remove(vendor_zip_path)
            print("    ✓ Cleaned up zip files.")
        except Exception:
            pass

    print("\n" + "=" * 70)
    print("  ✓ WAYDROID IMAGES ARE READY!")
    print("=" * 70)
    print(f"  System Image: {system_img}")
    print(f"  Vendor Image: {vendor_img}")
    print("=" * 70)

    if args.init:
        install_and_init(images_dir)
    else:
        print("\nTo initialize Waydroid using these images without downloading:")
        print("  sudo mkdir -p /etc/waydroid-extra/images")
        print(f"  sudo ln -sf {system_img} /etc/waydroid-extra/images/system.img")
        print(f"  sudo ln -sf {vendor_img} /etc/waydroid-extra/images/vendor.img")
        print("  sudo waydroid init -f")

if __name__ == "__main__":
    main()
