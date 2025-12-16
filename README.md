# Multi-Tool-Recon-Automation
A comprehensive bash script for automated reconnaissance that integrates multiple security tools into a unified pipeline.

# Features
# 🔍 Subdomain Enumeration
subfinder - Fast passive subdomain enumeration
assetfinder - Additional subdomain discovery
amass - Comprehensive OSINT subdomain enumeration
crt.sh - Certificate transparency logs
httpx - Live subdomain probing

# 🔌 Port Scanning
naabu - Fast port scanning
nmap - Detailed port and service detection
Automatic service version detection
Full port range scanning

# 📸 Web Screenshotting
gowitness - Fast web screenshotting
eyewitness - Alternative screenshotting tool
Automatic screenshot organization

# 🔗 URL Extraction
gau (GetAllUrls) - Fetch known URLs from archives
waybackurls - Wayback Machine URL extraction
Automatic URL categorization by file type
Separate lists for JS, PHP, ASPX, and static files

# 📄 JavaScript File Analysis
Automatic JS file downloading
Secret/credential pattern detection
Organized file storage with MD5 naming

# 📁 Directory Brute-forcing
ffuf - Fast web fuzzer
Customizable wordlists
Response code filtering
JSON output for further analysis

# 📊 Reporting
Automated report generation
Organized directory structure
Summary statistics
Timestamp tracking

Installation
# Step 1: Install Tools
bashchmod +x install_tools.sh
./install_tools.sh
This will install all required tools. Answer y to all prompts for full functionality.

# Step 2: Restart Terminal
bash# Close and reopen your terminal, or run:
source ~/.bashrc

# Step 3: Make Script Executable
bashchmod +x recon_automation.sh

# Step 4: Run Your First Scan
bash# Basic scan (recommended for first time)
./recon_automation.sh example.com

# Fast scan (skip intensive modules)
./recon_automation.sh example.com -p -d
Step 5: Review Results
bashcd recon_example.com_*
cat REPORT.txt

What Each Module Does
# 🔍 Subdomain Enumeration (-s to skip)

What it does: Finds all subdomains (dev.example.com, api.example.com, etc.)
Time: 2-5 minutes
Output: subdomains/all_subdomains.txt

# 🔌 Port Scanning (-p to skip)

What it does: Finds open ports and services
Time: 10-30 minutes (slow)
Output: ports/nmap_*.xml

# 📸 Screenshots (-w to skip)

What it does: Takes screenshots of all live websites
Time: 5-15 minutes
Output: screenshots/*.png

# 🔗 URL Extraction (-u to skip)

What it does: Finds historical URLs from archives
Time: 2-5 minutes
Output: urls/all_urls.txt

# 📄 JS Analysis (-j to skip)

What it does: Downloads and analyzes JavaScript files for secrets
Time: 5-10 minutes
Output: js_files/potential_secrets.txt

# 📁 Directory Bruteforce (-d to skip)

What it does: Finds hidden directories and files
Time: 5-20 minutes
Output: directories/ffuf_*.json


# Common Usage Patterns
Full Scan (Everything)
bash./recon_automation.sh target.com
Quick Scan (Fast, Skip Slow Modules)
bash./recon_automation.sh target.com -p -d
Subdomain Discovery Only
bash./recon_automation.sh target.com -p -w -u -j -d
URL & JS Analysis Only
bash./recon_automation.sh target.com -s -p -w -d

Reading the Results
Finding Live Subdomains
bashcat recon_*/subdomains/live_subdomains.txt
Finding Interesting URLs
bash# All URLs
cat recon_*/urls/all_urls.txt

# Just JavaScript files
cat recon_*/urls/js_urls.txt

# Just PHP files
cat recon_*/urls/php_urls.txt
Finding Secrets in JS Files
bashcat recon_*/js_files/potential_secrets.txt
Viewing Port Scan Results
bash# Human readable
cat recon_*/ports/nmap_full.nmap

# Import to other tools
cat recon_*/ports/nmap_full.xml

Improving Results
Add API Keys (Highly Recommended)
Subfinder (~/.config/subfinder/config.yaml):
yamlvirustotal: ["your-api-key"]
censys: ["api-id", "api-secret"]
shodan: ["your-api-key"]
github: ["your-github-token"]
Get free API keys from:

VirusTotal: https://www.virustotal.com/gui/join-us
Shodan: https://account.shodan.io/register
GitHub: https://github.com/settings/tokens

Use Better Wordlists
bash# Download SecLists (comprehensive)
sudo git clone https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/SecLists

# Use in directory bruteforce
# Edit recon_automation.sh line ~420:
local wordlist="/usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt"

Troubleshooting
"Command not found" errors
bash# Check if Go is in PATH
echo $PATH | grep go

# If not, add it:
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify
which subfinder
Script hangs or is very slow
bash# Skip slow modules
./recon_automation.sh target.com -p -d

# Or run in background
nohup ./recon_automation.sh target.com &
tail -f nohup.out
No subdomains found

Check internet connection
Try with known domain: ./recon_automation.sh google.com -p -w -u -j -d
Add API keys to tools
Check if domain has subdomains at all

Permission denied errors
bash# Make script executable
chmod +x recon_automation.sh

# Some tools need sudo (nmap, naabu)
sudo -E ./recon_automation.sh target.com

Advanced Tips
Run Multiple Domains
bash# Create domain list
cat > domains.txt << EOF
example1.com
example2.com
example3.com
EOF

# Run in parallel (3 at a time)
cat domains.txt | xargs -P 3 -I {} ./recon_automation.sh {}
Run in Background
bash# Using nohup
nohup ./recon_automation.sh target.com &

# Using screen
screen -S recon
./recon_automation.sh target.com
# Ctrl+A, D to detach
# screen -r recon to reattach

# Using tmux (recommended)
tmux new -s recon
./recon_automation.sh target.com
# Ctrl+B, D to detach
# tmux attach -t recon to reattach
Schedule Scans
bash# Add to crontab
crontab -e

# Run daily at 2 AM
0 2 * * * /path/to/recon_automation.sh target.com -p -d

Next Steps After Recon
1. Manual Verification

Visit live subdomains in browser
Check screenshots for interesting pages
Review port scan results for unusual services

2. Vulnerability Scanning
bash# Use nuclei on live hosts
cat recon_*/subdomains/live_subdomains.txt | nuclei -t cves/

# Use nikto for web vulnerabilities
cat recon_*/subdomains/live_subdomains.txt | while read url; do
    nikto -h "$url"
done
3. Content Discovery
bash# More thorough directory bruteforce
cat recon_*/subdomains/live_subdomains.txt | while read url; do
    ffuf -u "$url/FUZZ" -w /usr/share/wordlists/SecLists/Discovery/Web-Content/big.txt
done
4. Parameter Discovery
bash# Find GET parameters
cat recon_*/urls/all_urls.txt | grep "?" | unfurl keys | sort -u

Safety Reminders
# ⚠️ IMPORTANT:

Get Permission: Only scan targets you own or have written authorization to test
Respect Rate Limits: Don't overload servers
Follow Laws: Unauthorized scanning is illegal in most countries
Use VPN: Consider using a VPN for privacy
Check Scope: Verify you're allowed to scan discovered subdomains


Getting Help
# Check Logs
bash# Script logs errors to stderr
./recon_automation.sh target.com 2> errors.log

# Test Individual Tools
bash# Test if tools work
subfinder -d example.com
httpx -u https://example.com
nmap example.com

# Common Issues
rate limiting: Wait and try again, or add delays
Timeout errors: Check network connection
Empty results: Verify domain is active and has subdomains


# Prerequisites
Install required tools:
bash# Go-based tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/tomnomnom/waybackurls@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/ffuf/ffuf@latest
go install -v github.com/sensepost/gowitness@latest

# Amass (via package manager or go)
sudo apt install amass  # Debian/Ubuntu
# OR
go install -v github.com/owasp-amass/amass/v4/...@master

# Nmap (via package manager)
sudo apt install nmap  # Debian/Ubuntu
sudo yum install nmap  # RedHat/CentOS
brew install nmap      # macOS

# Optional: EyeWitness (Python-based)
git clone https://github.com/FortyNorthSecurity/EyeWitness.git
cd EyeWitness/Python/setup
sudo ./setup.sh

# jq for JSON parsing
sudo apt install jq
Script Setup
bash# Download the script
chmod +x recon_automation.sh

# Optional: Move to PATH
sudo mv recon_automation.sh /usr/local/bin/recon
Usage
Basic Usage
bash./recon_automation.sh example.com
Advanced Usage
bash# Skip specific modules
./recon_automation.sh example.com -s    # Skip subdomain enumeration
./recon_automation.sh example.com -p    # Skip port scanning
./recon_automation.sh example.com -w    # Skip screenshots
./recon_automation.sh example.com -u    # Skip URL extraction
./recon_automation.sh example.com -j    # Skip JS file collection
./recon_automation.sh example.com -d    # Skip directory bruteforce

# Combine options
./recon_automation.sh example.com -w -d # Skip screenshots and directory bruteforce

# Show help
./recon_automation.sh -h
Output Structure
recon_example.com_20231215_143022/
├── subdomains/
│   ├── all_subdomains.txt      # All discovered subdomains
│   ├── live_subdomains.txt     # HTTP/HTTPS accessible
│   ├── subfinder.txt
│   ├── assetfinder.txt
│   ├── amass.txt
│   └── crtsh.txt
├── ports/
│   ├── naabu_results.txt
│   ├── nmap_full.xml
│   ├── nmap_full.nmap
│   └── nmap_services.xml
├── screenshots/
│   └── [timestamp]_screenshot.png
├── urls/
│   ├── all_urls.txt            # All discovered URLs
│   ├── js_urls.txt             # JavaScript files
│   ├── php_urls.txt
│   ├── aspx_urls.txt
│   └── static_files.txt
├── js_files/
│   ├── downloads/              # Downloaded JS files
│   └── potential_secrets.txt   # Pattern matches
├── directories/
│   └── ffuf_*.json             # Directory bruteforce results
├── vulnerabilities/
└── REPORT.txt                  # Summary report
Configuration
Custom Wordlists
Edit the directory_bruteforce() function to use custom wordlists:
bashlocal wordlist="/path/to/your/wordlist.txt"
Recommended wordlists:

SecLists: https://github.com/danielmiessler/SecLists
FuzzDB: https://github.com/fuzzdb-project/fuzzdb
Assetnote: https://wordlists.assetnote.io/

# Adjusting Scan Intensity
Port Scanning Speed (in port_scanning() function):
bash# Fast scan
nmap -T4 -F ...

# More thorough (slower)
nmap -T3 -p- ...

# Aggressive
nmap -T5 -p- ...
Subdomain Enumeration (in subdomain_enumeration() function):
bash# More aggressive amass
amass enum -active -d "$domain" -o ...

# Best Practices Legal & Ethical
# ⚠️ IMPORTANT: Only run this script against targets you have explicit permission to test!
Get written authorization before scanning
Respect rate limits and robots.txt
Be aware of the target's infrastructure
Don't perform scans from corporate networks without approval

# Performance Tips
Run in tmux/screen - Scans can take hours

bash   tmux new -s recon
   ./recon_automation.sh example.com
   # Ctrl+B, then D to detach

# Use VPS for better bandwidth - Cloud servers often have better connectivity
Start with smaller scope - Skip intensive modules initially:

bash   ./recon_automation.sh example.com -p -d

# Parallel execution - For multiple domains:
bash   cat domains.txt | xargs -P 3 -I {} ./recon_automation.sh {}
Troubleshooting
Common Issues
"Tool not found" errors

Ensure Go bin is in PATH: export PATH=$PATH:$(go env GOPATH)/bin
Verify installation: which subfinder

# Rate limiting
Add delays between requests
Use API keys (subfinder, amass support this)
Run during off-peak hours

# Permission denied
Check script permissions: chmod +x recon_automation.sh
Some tools need sudo for raw sockets (nmap, naabu)

# No results from subdomain enumeration
Check internet connection
Verify domain name is correct
Some tools require API keys for full functionality

# Extending the Script
Adding New Tools
bash# Add to check_tools() function
local tools=("subfinder" "your-new-tool" ...)

# Create new function
your_new_module() {
    local output_dir=$1
    print_section "Your New Module"
    # Your code here
}

# Call in main()
your_new_module "$output_dir"
API Key Integration
Many tools support API keys for enhanced results:
bash# ~/.config/subfinder/config.yaml
virustotal: ["your-api-key"]
passivetotal: ["email", "key"]

# ~/.config/amass/config.ini
[data_sources.virustotal]
apikey = your-api-key
Integration with Other Tools
Feed results to nuclei (vulnerability scanning)
bashcat recon_*/subdomains/live_subdomains.txt | nuclei -t cves/ -o vulnerabilities.txt

# Import to Burp Suite
bash# Convert to Burp-friendly format
cat recon_*/urls/all_urls.txt > burp_targets.txt
Visualize with Aquatone (deprecated but useful)
bashcat recon_*/subdomains/live_subdomains.txt | aquatone
Contributing

# Feel free to:
Add new reconnaissance modules
Improve existing functions
Add error handling
Optimize performance
Submit wordlists

# Changelog
v1.0 - Initial release

# Subdomain enumeration (4 tools)
Port scanning (nmap, naabu)
Web screenshotting
URL extraction
JS file analysis
Directory bruteforce
Automated reporting

# License
This script is provided for educational and authorized testing purposes only.
Credits
This script integrates the following excellent tools:

ProjectDiscovery (subfinder, httpx, naabu, nuclei)
OWASP Amass
Tom Hudson (assetfinder, waybackurls)
ffuf
nmap
gowitness
And many others in the security community

Disclaimer
This tool is for authorized security testing only. Unauthorized access to computer systems is illegal. Always obtain proper authorization before conducting security assessments.
