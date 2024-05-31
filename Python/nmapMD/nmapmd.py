#!/usr/bin/env python3

import nmap
import argparse
import random
import sys
import subprocess

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

def print_usage():
    usage = """
    Usage:
      nmapMD -o output.md -- nmap arguments

    Options:
      -o, --output        Specify the output markdown file name.
      -h, --help          Show this help message and exit.

    Examples:
      nmapMD -o output.md -- 192.168.1.1 -sV -T4
      nmapMD -o output.md -- -iL 192_hosts.txt -sC -sV -vv
    """
    print(usage)

def run_nmap_scan(targets, options):
    command = f"nmap {targets} {options}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            print(output.strip())
    return process.poll()

def generate_markdown(nm, output_file):
    # Placeholder for actual Markdown generation logic
    pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run nmap scan and output results to a Markdown file.', add_help=False)
    parser.add_argument('-o', '--output', help='Output markdown file name')
    parser.add_argument('nmap_args', nargs=argparse.REMAINDER, help='Arguments to pass to nmap. Start with "--" before nmap arguments.')
    args = parser.parse_args()

    if '-h' in args.nmap_args or '--help' in args.nmap_args or not sys.argv[1:]:
        print_banner()
        print_usage()
        sys.exit()

    if not args.nmap_args or args.nmap_args[0] != '--':
        print_banner()
        print_usage()
        sys.exit(1)

    nmap_args = args.nmap_args[1:]
    if not nmap_args:
        print("No nmap arguments provided after '--'. Exiting.")
        sys.exit(1)

    if args.output:
        markdown_output_file = args.output
    else:
        random_number = random.randint(100, 999)
        markdown_output_file = f"nmapMD_hosts_{random_number}.md"

    targets, options = nmap_args[0], ' '.join(nmap_args[1:])
    run_nmap_scan(targets, options)
    print(f"Markdown file '{markdown_output_file}' has been generated.")
