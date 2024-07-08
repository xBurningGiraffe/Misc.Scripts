#!/usr/bin/python3

import argparse
import requests
import dns.resolver
import socket
import subprocess
import re
import json

# Function to validate subdomain
def is_valid_subdomain(subdomain):
    pattern = re.compile(
        r'^(?:[a-zA-Z0-9-_]{1,63}\.)*[a-zA-Z0-9][a-zA-Z0-9-_]{0,62}\.[a-zA-Z]{2,6}$'
    )
    return bool(pattern.match(subdomain))

# Function to check reachability
def is_reachable(subdomain, timeout):
    try:
        print(f"[+] Checking reachability for {subdomain}...")
        response = requests.get(f"http://{subdomain}", timeout=timeout)
        return True, response.status_code
    except requests.ConnectionError:
        return False, None
    except requests.exceptions.ReadTimeout:
        print(f"[!] Read timeout occurred for {subdomain}")
        return False, None

# Function to detect services
def detect_services(subdomain):
    try:
        print(f"[+] Detecting services for {subdomain}...")
        ip = socket.gethostbyname(subdomain)
        services = []
        for port in [80, 443]:  # Extend this list with other ports as necessary
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((ip, port))
            if result == 0:
                services.append(port)
            sock.close()
        return services
    except socket.error:
        return []

# Function to enumerate technologies using WhatWeb CLI
def enumerate_technologies(subdomain):
    try:
        print(f"[+] Enumerating technologies for {subdomain} using WhatWeb...")
        result = subprocess.run(['whatweb', f'http://{subdomain}'], capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        print(f"[!] Error enumerating technologies for {subdomain}: {e}")
        return "Error"

# Function to brute-force directories and files using feroxbuster
def brute_force_directories(subdomain):
    try:
        print(f"[+] Brute-forcing directories for {subdomain} using feroxbuster...")
        result = subprocess.run([
            'feroxbuster', 
            '-u', f'http://{subdomain}', 
            '-w', '/usr/share/seclists/Discovery/Web-Content/big.txt', 
            '-q', '-t', '10'
        ], capture_output=True, text=True)
        
        directories = []
        for line in result.stdout.splitlines():
            if '200' in line or '301' in line:
                directories.append(line.split()[0])
        return directories
    except Exception as e:
        print(f"[!] Error brute-forcing directories for {subdomain}: {e}")
        return []

# Function to run nuclei scans
def run_nuclei(subdomain):
    try:
        print(f"[+] Running nuclei scan for {subdomain}...")
        result = subprocess.run(['nuclei', '-u', f'http://{subdomain}'], capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        print(f"[!] Error running nuclei for {subdomain}: {e}")
        return "Error"

# Main function to enumerate subdomains
def enumerate_subdomains(subdomains, timeout):
    results = []
    for subdomain in subdomains:
        if not is_valid_subdomain(subdomain):
            print(f"[-] Skipping invalid subdomain: {subdomain}")
            continue
        print(f"[+] Enumerating {subdomain}...")
        reachable, status_code = is_reachable(subdomain, timeout)
        if reachable:
            services = detect_services(subdomain)
            technologies = enumerate_technologies(subdomain)
            directories = brute_force_directories(subdomain)
            nuclei_results = run_nuclei(subdomain)
            results.append({
                'subdomain': subdomain,
                'status_code': status_code,
                'services': services,
                'technologies': technologies,
                'directories': directories,
                'nuclei_results': nuclei_results
            })
        else:
            results.append({
                'subdomain': subdomain,
                'reachable': False
            })
    return results

# Function to save results to a JSON file
def save_results_to_json(results, output_file):
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=4)
    print(f"[+] Results saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Subdomain Enumeration Tool")
    parser.add_argument("file", help="File containing list of subdomains to enumerate")
    parser.add_argument("--timeout", type=int, default=5, help="Timeout for reachability checks (default: 5 seconds)")
    parser.add_argument("--output", type=str, default="results.json", help="Output file to save the results (default: results.json)")

    args = parser.parse_args()
    file_path = args.file
    timeout = args.timeout
    output_file = args.output

    with open(file_path, 'r') as file:
        subdomains = [line.strip() for line in file if line.strip()]

    results = enumerate_subdomains(subdomains, timeout)
    
    for result in results:
        print(json.dumps(result, indent=4))
    
    save_results_to_json(results, output_file)
