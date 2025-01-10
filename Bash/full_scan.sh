#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Global Variables
INPUT_FILE=""
OUTPUT_CSV=""
PORTS="80,443,8080,8443,9443"
RUN_ALL=false
RUN_NMAP=false
RUN_DIG=false
RUN_SSLYZE=false

# Associative arrays to store data
declare -A OPEN_PORTS_MAP
declare -A DOMAINS_MAP
declare -A SSL_COMPLIANCE_MAP
declare -A SSL_ISSUES_MAP

# Function: Display Help
show_help() {
    cat << EOF
Usage: $0 -i <input_file> [ -o <output_csv> ] [options]

Options:
  -a, --all          Run all functions: nmap, nslookup, sslyze
  -n, --nmap         Perform nmap scanning only
  -d, --dig          Perform reverse DNS lookups (using nslookup) only
  -s, --sslyze       Perform sslyze scans only
  -i, --input        Specify input file with subnets or IPs
  -o, --output       Specify output CSV file (optional)
  -h, --help         Display help information

Examples:
  $0 -i subnets.txt -o results.csv -a
  $0 -i subnets.txt -n -d
EOF
}

# Function: Initialize Output
initialize_output() {
    if [[ -n "$OUTPUT_CSV" ]]; then
        if [[ ! -f "$OUTPUT_CSV" ]]; then
            echo "IP Address,Domain,Open Ports,SSL Compliance Status,Compliance Issues" > "$OUTPUT_CSV"
        fi
    else
        printf "%-15s | %-30s | %-15s | %-25s | %-100s\n" "IP Address" "Domain" "Open Ports" "SSL Compliance Status" "Compliance Issues"
        printf "%0.s-" {1..150}
        echo
    fi
}

# Function: Perform nmap scan
run_nmap() {
    echo "Starting Nmap scan..."
    while IFS= read -r SUBNET || [[ -n "$SUBNET" ]]; do
        SUBNET=$(echo "$SUBNET" | xargs)
        [[ -z "$SUBNET" || "$SUBNET" =~ ^# ]] && continue

        echo "Scanning $SUBNET with Nmap..."
        NMAP_OUTPUT=$(sudo nmap -n -sn "$SUBNET" -oG - 2>/dev/null) || {
            echo "Nmap scan failed for $SUBNET"
            continue
        }

        while IFS= read -r LINE; do
            if [[ $LINE =~ ^Host: ]]; then
                HOST_IP=$(echo "$LINE" | awk '{print $2}')
                PORTS_FIELD=$(echo "$LINE" | sed -n 's/.*Ports: \(.*\)/\1/p')
                if [[ -n "$PORTS_FIELD" ]]; then
                    OPEN_PORTS=$(echo "$PORTS_FIELD" | grep -oE '[0-9]+/open' | cut -d'/' -f1 | paste -sd ",")
                else
                    OPEN_PORTS="None"
                fi
                OPEN_PORTS_MAP["$HOST_IP"]="$OPEN_PORTS"
            fi
        done <<< "$NMAP_OUTPUT"
    done < "$INPUT_FILE"
    echo "Nmap scan completed."
}

expand_subnet() {
    local SUBNET="$1"
    python3 -c "
import ipaddress
for ip in ipaddress.IPv4Network('$SUBNET', strict=False):
    print(ip)
"
}


# Function: Perform reverse DNS lookups using nslookup
run_nslookup() {
    echo "Starting DNS lookups..."
    local IP_LIST=()

    if [[ "$RUN_NMAP" == true || "$RUN_ALL" == true ]]; then
        # Use IPs from nmap results
        IP_LIST=(${!OPEN_PORTS_MAP[@]})
    else
        # Expand subnets manually if only -d is provided
        while IFS= read -r ENTRY || [[ -n "$ENTRY" ]]; do
            ENTRY=$(echo "$ENTRY" | xargs)
            [[ -z "$ENTRY" || "$ENTRY" =~ ^# ]] && continue

            if [[ "$ENTRY" == */* ]]; then
                echo "Expanding subnet: $ENTRY"
                IP_LIST+=($(expand_subnet "$ENTRY"))
            else
                IP_LIST+=("$ENTRY")
            fi
        done < "$INPUT_FILE"
    fi

    # Perform DNS lookups for each IP
    for IP in "${IP_LIST[@]}"; do
        echo "Processing IP: $IP"
        NSLOOKUP_OUTPUT=$(timeout 5 nslookup "$IP" 2>/dev/null || echo "Error")
        
        if [[ "$NSLOOKUP_OUTPUT" == "Error" ]]; then
            echo "Error resolving $IP. Skipping..."
            DOMAINS_MAP["$IP"]="$IP"  # Default to IP if resolution fails
            continue
        fi

        PTR_RECORDS=$(echo "$NSLOOKUP_OUTPUT" | awk '/name =/ {print $NF}' | sed 's/\.$//')
        if [[ -n "$PTR_RECORDS" ]]; then
            DOMAINS_MAP["$IP"]=$(echo "$PTR_RECORDS" | tr '\n' ',' | sed 's/,$//')
        else
            DOMAINS_MAP["$IP"]="$IP"  # Default to IP if no PTR records are found
        fi
    done
    echo "DNS lookups completed."
}






# Function: Run sslyze scans
run_sslyze_scans() {
    echo "Starting SSLyze scans..."
    for IP in "${!OPEN_PORTS_MAP[@]}"; do
        DOMAIN_LIST="${DOMAINS_MAP[$IP]}"
        for TARGET in $(echo "$DOMAIN_LIST" | tr ',' ' '); do
            echo "Validating domain $TARGET with openssl (5s timeout)..."

            # OpenSSL Validation with Timeout
            if timeout 5 openssl s_client -connect "$TARGET:443" -servername "$TARGET" < /dev/null >/dev/null 2>&1; then
                echo "OpenSSL handshake successful for $TARGET."
            else
                echo "OpenSSL handshake failed for $TARGET. Skipping SSL scan."
                SSL_COMPLIANCE_MAP["$TARGET"]="Error"
                SSL_ISSUES_MAP["$TARGET"]="OpenSSL handshake failed or timed out"
                continue
            fi


            # Proceed with SSLyze Scan
            echo "Scanning SSL for $TARGET..."
            SSLSCAN_OUTPUT=$(timeout 300 sslyze --regular --certinfo "$TARGET" 2>/dev/null || echo "Error")

            if [[ "$SSLSCAN_OUTPUT" == "Error" ]]; then
                SSL_COMPLIANCE_MAP["$TARGET"]="Error"
                SSL_ISSUES_MAP["$TARGET"]="SSL scan failed (timeout or connectivity issue)"
                continue
            fi

            # Check for handshake issues
            if echo "$SSLSCAN_OUTPUT" | grep -q "Could not complete an SSL handshake"; then
                SSL_COMPLIANCE_MAP["$TARGET"]="Error"
                SSL_ISSUES_MAP["$TARGET"]="SSL handshake failed"
                continue
            fi

            # Additional SSL checks as needed...
            SSL_COMPLIANCE_MAP["$TARGET"]="Compliant"
            SSL_ISSUES_MAP["$TARGET"]="None"
        done
    done
    echo "SSLyze scans completed."
}



# Function: Populate Output
populate_output() {
    for IP in "${!OPEN_PORTS_MAP[@]}"; do
        DOMAIN="${DOMAINS_MAP[$IP]:-$IP}"  # Fallback to IP
        OPEN_PORTS="${OPEN_PORTS_MAP[$IP]:-N/A}"
        SSL_STATUS="${SSL_COMPLIANCE_MAP[$IP]:-N/A}"
        SSL_ISSUES="${SSL_ISSUES_MAP[$IP]:-N/A}"

        if [[ -n "$OUTPUT_CSV" ]]; then
            echo "$IP,$DOMAIN,$OPEN_PORTS,$SSL_STATUS,$SSL_ISSUES" >> "$OUTPUT_CSV"
        else
            printf "%-15s | %-30s | %-15s | %-25s | %-100s\n" "$IP" "$DOMAIN" "$OPEN_PORTS" "$SSL_STATUS" "$SSL_ISSUES"
        fi
    done
}


# Function: Parse Command-Line Arguments
parse_arguments() {
    local PARSED_OPTIONS
    PARSED_OPTIONS=$(getopt -n "$0" -o andsi:o:h --long all,nmap,dig,sslyze,input:,output:,help -- "$@") || {
        show_help
        exit 1
    }

    eval set -- "$PARSED_OPTIONS"

    while true; do
        case "$1" in
            -a|--all)
                RUN_ALL=true
                RUN_NMAP=true
                RUN_DIG=true
                RUN_SSLYZE=true
                shift
                ;;
            -n|--nmap)
                RUN_NMAP=true
                shift
                ;;
            -d|--dig)
                RUN_DIG=true
                shift
                ;;
            -s|--sslyze)
                RUN_SSLYZE=true
                shift
                ;;
            -i|--input)
                INPUT_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_CSV="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Invalid option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}


# Main Execution Flow
main() {
    parse_arguments "$@"

    if [[ -z "$INPUT_FILE" ]]; then
        echo "Error: Input file is required."
        show_help
        exit 1
    fi

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: Input file '$INPUT_FILE' does not exist."
        exit 1
    fi

    initialize_output

    [[ "$RUN_NMAP" == true ]] && run_nmap
    [[ "$RUN_DIG" == true ]] && run_nslookup
    [[ "$RUN_SSLYZE" == true ]] && run_sslyze_scans

    populate_output

    echo "All selected operations completed."
    [[ -n "$OUTPUT_CSV" ]] && echo "Results saved to '$OUTPUT_CSV'."
}

main "$@"
