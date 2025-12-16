#!/bin/bash

###########################################
# Multi-Tool Recon Automation Script
# Full reconnaissance pipeline automation
###########################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Multi-Tool Recon Automation Script v1.0           ║
║              Full Reconnaissance Pipeline                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Print status messages
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_section() {
    echo -e "\n${MAGENTA}[===]${NC} ${CYAN}$1${NC} ${MAGENTA}[===]${NC}\n"
}

# Check if required tools are installed
check_tools() {
    print_section "Checking Required Tools"
    
    local tools=("subfinder" "assetfinder" "amass" "nmap" "naabu" "gowitness" "gau" "waybackurls" "ffuf" "httpx" "nuclei")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool is installed"
        else
            print_warning "$tool is NOT installed (optional but recommended)"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_warning "Missing tools: ${missing_tools[*]}"
        print_warning "Some modules may be skipped"
        echo ""
        read -p "Continue anyway? (y/n): " continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            print_error "Exiting..."
            exit 1
        fi
    fi
}

# Create organized directory structure
create_directories() {
    local domain=$1
    local base_dir="recon_${domain}_$(date +%Y%m%d_%H%M%S)"
    
    print_section "Creating Directory Structure"
    
    mkdir -p "$base_dir"/{subdomains,ports,screenshots,urls,js_files,directories,vulnerabilities}
    
    print_success "Created base directory: $base_dir"
    echo "$base_dir"
}

# Subdomain enumeration
subdomain_enumeration() {
    local domain=$1
    local output_dir=$2
    
    print_section "Subdomain Enumeration"
    
    local subdomain_file="$output_dir/subdomains/all_subdomains.txt"
    
    # Subfinder
    if command -v subfinder &> /dev/null; then
        print_status "Running subfinder..."
        subfinder -d "$domain" -all -o "$output_dir/subdomains/subfinder.txt" 2>/dev/null
        print_success "Subfinder completed"
    fi
    
    # Assetfinder
    if command -v assetfinder &> /dev/null; then
        print_status "Running assetfinder..."
        assetfinder --subs-only "$domain" > "$output_dir/subdomains/assetfinder.txt" 2>/dev/null
        print_success "Assetfinder completed"
    fi
    
    # Amass (passive mode for speed)
    if command -v amass &> /dev/null; then
        print_status "Running amass (passive mode)..."
        amass enum -passive -d "$domain" -o "$output_dir/subdomains/amass.txt" 2>/dev/null
        print_success "Amass completed"
    fi
    
    # crt.sh via curl
    print_status "Querying crt.sh..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > "$output_dir/subdomains/crtsh.txt" 2>/dev/null
    print_success "crt.sh query completed"
    
    # Combine and deduplicate all subdomains
    print_status "Combining and deduplicating subdomains..."
    cat "$output_dir/subdomains/"*.txt 2>/dev/null | sort -u > "$subdomain_file"
    
    local count=$(wc -l < "$subdomain_file")
    print_success "Found $count unique subdomains"
    
    # Probe for live subdomains
    if command -v httpx &> /dev/null; then
        print_status "Probing for live subdomains with httpx..."
        cat "$subdomain_file" | httpx -silent -threads 50 -o "$output_dir/subdomains/live_subdomains.txt" 2>/dev/null
        local live_count=$(wc -l < "$output_dir/subdomains/live_subdomains.txt")
        print_success "Found $live_count live subdomains"
    fi
}

# Port scanning
port_scanning() {
    local output_dir=$1
    
    print_section "Port Scanning"
    
    local subdomain_file="$output_dir/subdomains/all_subdomains.txt"
    
    if [ ! -f "$subdomain_file" ]; then
        print_error "Subdomain file not found. Skipping port scanning."
        return
    fi
    
    # Naabu (faster)
    if command -v naabu &> /dev/null; then
        print_status "Running naabu for fast port scanning..."
        naabu -list "$subdomain_file" -top-ports 1000 -o "$output_dir/ports/naabu_results.txt" -silent 2>/dev/null
        print_success "Naabu scan completed"
    fi
    
    # Nmap on live hosts (more detailed)
    if command -v nmap &> /dev/null && [ -f "$output_dir/subdomains/live_subdomains.txt" ]; then
        print_status "Running nmap for detailed scanning (this may take a while)..."
        
        # Extract just the domains from httpx output
        cat "$output_dir/subdomains/live_subdomains.txt" | sed 's|http[s]*://||' | cut -d'/' -f1 | sort -u > "$output_dir/ports/hosts_to_scan.txt"
        
        nmap -iL "$output_dir/ports/hosts_to_scan.txt" -T4 -Pn -p- --open -oA "$output_dir/ports/nmap_full" 2>/dev/null
        print_success "Nmap scan completed"
        
        # Service detection on open ports
        if [ -f "$output_dir/ports/nmap_full.xml" ]; then
            print_status "Running service detection..."
            nmap -iL "$output_dir/ports/hosts_to_scan.txt" -sV -sC -Pn -oA "$output_dir/ports/nmap_services" 2>/dev/null
            print_success "Service detection completed"
        fi
    fi
}

# Screenshotting
screenshotting() {
    local output_dir=$1
    
    print_section "Web Screenshotting"
    
    local live_file="$output_dir/subdomains/live_subdomains.txt"
    
    if [ ! -f "$live_file" ]; then
        print_error "Live subdomains file not found. Skipping screenshots."
        return
    fi
    
    # Gowitness
    if command -v gowitness &> /dev/null; then
        print_status "Taking screenshots with gowitness..."
        gowitness file -f "$live_file" -P "$output_dir/screenshots/" --disable-logging 2>/dev/null
        print_success "Gowitness screenshots completed"
    elif command -v eyewitness &> /dev/null; then
        print_status "Taking screenshots with EyeWitness..."
        eyewitness -f "$live_file" -d "$output_dir/screenshots/eyewitness" --no-prompt 2>/dev/null
        print_success "EyeWitness screenshots completed"
    else
        print_warning "No screenshot tool available (gowitness/eyewitness)"
    fi
}

# URL extraction
url_extraction() {
    local domain=$1
    local output_dir=$2
    
    print_section "URL Extraction"
    
    local url_file="$output_dir/urls/all_urls.txt"
    
    # GAU (Get All URLs)
    if command -v gau &> /dev/null; then
        print_status "Running gau..."
        echo "$domain" | gau --threads 5 --o "$output_dir/urls/gau.txt" 2>/dev/null
        print_success "GAU completed"
    fi
    
    # Waybackurls
    if command -v waybackurls &> /dev/null; then
        print_status "Running waybackurls..."
        echo "$domain" | waybackurls > "$output_dir/urls/waybackurls.txt" 2>/dev/null
        print_success "Waybackurls completed"
    fi
    
    # Combine and deduplicate URLs
    print_status "Combining and deduplicating URLs..."
    cat "$output_dir/urls/"*.txt 2>/dev/null | sort -u > "$url_file"
    
    local count=$(wc -l < "$url_file")
    print_success "Found $count unique URLs"
    
    # Filter URLs by extension
    print_status "Categorizing URLs..."
    grep -iE '\.js(\?|$)' "$url_file" > "$output_dir/urls/js_urls.txt" 2>/dev/null || touch "$output_dir/urls/js_urls.txt"
    grep -iE '\.php(\?|$)' "$url_file" > "$output_dir/urls/php_urls.txt" 2>/dev/null || touch "$output_dir/urls/php_urls.txt"
    grep -iE '\.aspx?(\?|$)' "$url_file" > "$output_dir/urls/aspx_urls.txt" 2>/dev/null || touch "$output_dir/urls/aspx_urls.txt"
    grep -iE '\.(jpg|jpeg|png|gif|svg|css|woff|ttf)(\?|$)' "$url_file" > "$output_dir/urls/static_files.txt" 2>/dev/null || touch "$output_dir/urls/static_files.txt"
    
    print_success "URL categorization completed"
}

# JS file collection
js_file_collection() {
    local output_dir=$1
    
    print_section "JavaScript File Collection"
    
    local js_urls="$output_dir/urls/js_urls.txt"
    
    if [ ! -f "$js_urls" ] || [ ! -s "$js_urls" ]; then
        print_error "No JavaScript URLs found. Skipping JS collection."
        return
    fi
    
    print_status "Downloading JavaScript files..."
    
    mkdir -p "$output_dir/js_files/downloads"
    
    local count=0
    while IFS= read -r url; do
        ((count++))
        local filename=$(echo "$url" | md5sum | cut -d' ' -f1).js
        curl -s -L "$url" -o "$output_dir/js_files/downloads/$filename" 2>/dev/null
        
        if [ $((count % 10)) -eq 0 ]; then
            echo -ne "\rDownloaded $count files..."
        fi
    done < "$js_urls"
    
    echo ""
    print_success "Downloaded JavaScript files"
    
    # Extract sensitive information from JS files
    print_status "Analyzing JS files for secrets..."
    grep -rEi '(api[_-]?key|apikey|api[_-]?secret|access[_-]?token|auth[_-]?token|aws[_-]?key|s3[_-]?bucket|password|passwd|pwd|secret)' "$output_dir/js_files/downloads/" > "$output_dir/js_files/potential_secrets.txt" 2>/dev/null || touch "$output_dir/js_files/potential_secrets.txt"
    
    if [ -s "$output_dir/js_files/potential_secrets.txt" ]; then
        print_success "Found potential secrets in JS files"
    else
        print_status "No obvious secrets found in JS files"
    fi
}

# Directory brute-forcing
directory_bruteforce() {
    local output_dir=$1
    
    print_section "Directory Brute-forcing"
    
    local live_file="$output_dir/subdomains/live_subdomains.txt"
    
    if [ ! -f "$live_file" ]; then
        print_error "Live subdomains file not found. Skipping directory bruteforce."
        return
    fi
    
    if ! command -v ffuf &> /dev/null; then
        print_error "ffuf not installed. Skipping directory bruteforce."
        return
    fi
    
    # Create or download wordlist
    local wordlist="/usr/share/wordlists/dirb/common.txt"
    
    if [ ! -f "$wordlist" ]; then
        print_warning "Default wordlist not found. Creating basic wordlist..."
        cat > "$output_dir/directories/basic_wordlist.txt" << 'WORDLIST_EOF'
admin
api
backup
config
dashboard
dev
login
panel
test
upload
wp-admin
.git
.env
.htaccess
robots.txt
sitemap.xml
WORDLIST_EOF
        wordlist="$output_dir/directories/basic_wordlist.txt"
    fi
    
    print_status "Starting directory bruteforce (limiting to first 5 hosts for demo)..."
    
    local host_count=0
    while IFS= read -r url && [ $host_count -lt 5 ]; do
        ((host_count++))
        local domain=$(echo "$url" | sed 's|http[s]*://||' | cut -d'/' -f1)
        
        print_status "Scanning $url..."
        ffuf -u "$url/FUZZ" -w "$wordlist" -mc 200,204,301,302,307,401,403 -o "$output_dir/directories/ffuf_${domain}.json" -of json -s 2>/dev/null
        
    done < "$live_file"
    
    print_success "Directory bruteforce completed"
}

# Generate report
generate_report() {
    local domain=$1
    local output_dir=$2
    
    print_section "Generating Report"
    
    local report="$output_dir/REPORT.txt"
    
    cat > "$report" << EOF
╔═══════════════════════════════════════════════════════════╗
║          Reconnaissance Report for $domain
║          Generated: $(date)
╚═══════════════════════════════════════════════════════════╝

[+] SUBDOMAINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Subdomains: $(wc -l < "$output_dir/subdomains/all_subdomains.txt" 2>/dev/null || echo "0")
Live Subdomains: $(wc -l < "$output_dir/subdomains/live_subdomains.txt" 2>/dev/null || echo "0")

[+] PORTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Port Scan Results: $output_dir/ports/

[+] URLS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total URLs: $(wc -l < "$output_dir/urls/all_urls.txt" 2>/dev/null || echo "0")
JavaScript URLs: $(wc -l < "$output_dir/urls/js_urls.txt" 2>/dev/null || echo "0")

[+] JAVASCRIPT FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Downloaded Files: $(ls -1 "$output_dir/js_files/downloads/" 2>/dev/null | wc -l)
Potential Secrets Found: $(wc -l < "$output_dir/js_files/potential_secrets.txt" 2>/dev/null || echo "0")

[+] SCREENSHOTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Location: $output_dir/screenshots/

[+] DIRECTORY ENUMERATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Results: $output_dir/directories/

[+] OUTPUT STRUCTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$output_dir/
├── subdomains/         All subdomain enumeration results
├── ports/              Port scanning results
├── screenshots/        Web screenshots
├── urls/               Extracted URLs
├── js_files/           JavaScript files and analysis
├── directories/        Directory bruteforce results
└── vulnerabilities/    Vulnerability scan results

EOF
    
    print_success "Report generated: $report"
    cat "$report"
}

# Main execution
main() {
    banner
    
    # Check for domain argument
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <domain> [options]"
        echo ""
        echo "Options:"
        echo "  -s    Skip subdomain enumeration"
        echo "  -p    Skip port scanning"
        echo "  -w    Skip screenshotting"
        echo "  -u    Skip URL extraction"
        echo "  -j    Skip JS file collection"
        echo "  -d    Skip directory bruteforce"
        echo "  -h    Show this help message"
        echo ""
        echo "Example: $0 example.com"
        echo "Example: $0 example.com -s -w"
        exit 1
    fi
    
    local domain=$1
    shift
    
    # Parse options
    local skip_subdomains=false
    local skip_ports=false
    local skip_screenshots=false
    local skip_urls=false
    local skip_js=false
    local skip_dirs=false
    
    while getopts "spwujdh" opt; do
        case $opt in
            s) skip_subdomains=true ;;
            p) skip_ports=true ;;
            w) skip_screenshots=true ;;
            u) skip_urls=true ;;
            j) skip_js=true ;;
            d) skip_dirs=true ;;
            h) main; exit 0 ;;
            *) print_error "Invalid option"; exit 1 ;;
        esac
    done
    
    print_status "Starting reconnaissance for: $domain"
    
    # Check tools
    check_tools
    
    # Create directories
    local output_dir=$(create_directories "$domain")
    
    # Run modules
    [ "$skip_subdomains" = false ] && subdomain_enumeration "$domain" "$output_dir"
    [ "$skip_ports" = false ] && port_scanning "$output_dir"
    [ "$skip_screenshots" = false ] && screenshotting "$output_dir"
    [ "$skip_urls" = false ] && url_extraction "$domain" "$output_dir"
    [ "$skip_js" = false ] && js_file_collection "$output_dir"
    [ "$skip_dirs" = false ] && directory_bruteforce "$output_dir"
    
    # Generate report
    generate_report "$domain" "$output_dir"
    
    print_section "Reconnaissance Complete!"
    print_success "All results saved to: $output_dir"
}

# Run main function
main "$@"
