#!/usr/bin/env python3

import re
import subprocess
import argparse
import random
import shlex

def print_banner():
    banner = """
  _   _                       __  __ _____  
 | \ | |                     |  \/  |  __ \ 
 |  \| |_ __ ___   __ _ _ __ | \  / | |  | |
 | . ` | '_ ` _ \ / _` | '_ \| |\/| | |  | |
 | |\  | | | | | | (_| | |_) | |  | | |__| |
 |_| \_|_| |_| |_|\__,_| .__/|_|  |_|_____/ 
                       | |                  
                       |_|               
                       
    Created by: xBurningGiraffe
    https://github.com/xBurningGiraffe
    """
    colors = ["\033[91m", "\033[92m", "\033[93m", "\033[94m", "\033[95m", "\033[96m", "\033[97m"]
    color_end = "\033[0m"
    color = random.choice(colors)
    print(color + banner + color_end)

def run_nmap_scan(nmap_args, output_file):
    command = ["sudo", "nmap"] + nmap_args + ["-oN", output_file]
    subprocess.run(command, check=True)

def parse_nmap_file(nmap_file):
    hosts = []
    with open(nmap_file, 'r') as file:
        content = file.read()

    host_pattern = re.compile(r'Nmap scan report for (.+?) \((.+?)\)')
    ip_pattern = re.compile(r'Nmap scan report for (.+)')
    os_pattern = re.compile(r'OS details: (.+)', re.MULTILINE)
    port_pattern = re.compile(r'(\d+)/tcp\s+open\s+(\S+)\s+(.+)')

    current_host = {}
    for line in content.split('\n'):
        if 'Nmap scan report for' in line:
            if current_host:
                hosts.append(current_host)
            current_host = {'hostname': 'N/A', 'ip_address': 'N/A', 'os': 'N/A', 'open_ports': [], 'notes': 'N/A'}
            ip_host_match = ip_pattern.match(line)
            if ip_host_match:
                current_host['ip_address'] = ip_host_match.group(1)
            host_match = host_pattern.match(line)
            if host_match:
                current_host['hostname'] = host_match.group(1)
                current_host['ip_address'] = host_match.group(2)
        elif 'OS details:' in line:
            os_match = os_pattern.match(line)
            if os_match:
                current_host['os'] = os_match.group(1)
        elif 'tcp open' in line:
            port_match = port_pattern.match(line)
            if port_match:
                port_info = f"{port_match.group(1)}/tcp {port_match.group(2)} {port_match.group(3)}"
                current_host['open_ports'].append(port_info)

    if current_host:
        hosts.append(current_host)

    return hosts

def generate_markdown(hosts, output_file):
    with open(output_file, 'w') as file:
        file.write("# Hostnames and IP Addresses\n\n")
        file.write("## Discovered Hosts\n")
        file.write("| Hostname | IP Address | OS | Open Ports | Notes |\n")
        file.write("|----------|-------------|----|------------|-------|\n")
        for host in hosts:
            ports_list = '<ul>' + ''.join(f"<li>{port}</li>" for port in host['open_ports']) + '</ul>'
            file.write(f"| {host['hostname']} | {host['ip_address']} | {host['os']} | {ports_list} | {host['notes']} |\n")

if __name__ == "__main__":
    print_banner()
    parser = argparse.ArgumentParser(description='Run nmap scan and output results to a Markdown file.')
    parser.add_argument('-o', '--output', default='discovered_hosts.md', help='Output markdown file name (default: discovered_hosts.md)')
    parser.add_argument('nmap_args', help='Arguments to pass to nmap, provided as a single string')
    args = parser.parse_args()

    nmap_output_file = "scan_results.nmap"
    markdown_output_file = args.output

    # Split the nmap_args string into a list of arguments
    nmap_args = shlex.split(args.nmap_args.replace(',', ' '))

    run_nmap_scan(nmap_args, nmap_output_file)
    hosts = parse_nmap_file(nmap_output_file)
    generate_markdown(hosts, markdown_output_file)
    print(f"Markdown file '{markdown_output_file}' has been generated.")
