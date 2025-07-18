# Recon
## FFuF
```bash
ffuf -c [colorize output] -mc 200,301 [match status codes] -fc 404 [exclude status codes from response] -u https://google.com/FUZZ -w [WORDLIST_PATH] -recursion -e .exe [files with .exe] -s [silent] -of html [output in html file] -o output-file -b "cookie1=smth; cookie2=smth" -H "X-Custom-Header: smth" -se [stop on errors] -p 2 [2 second delay] -t 150 [threads]


################
### EXAMPLES ###
################
# classic directory FUZZ
ffuf -c -fc 404 -u http://example.com/FUZZ -w ~/SecLists/Discovery/Web-Content/raft-medium-words.txt

ffuf -c -mc 200,301 -fc 404 -u http://example.com/FUZZ -w ~/seclists/discovery/web-content/raft-large-words.txt -t 150 -e '.php,.html'
ffuf -c -fc 404 -u http://example.com/FUZZ -w ~/SecLists/Discovery/Web-Content/raft-large-words.txt -t 150 -e $(cat /root/SecLists/Discovery/Web-Content/web-extensions-comma_separated.txt)

# FUZZ HTTP verbs
ffuf -c -u 'http://WIN-KML6TP4LOOL.CONTOSO.ORG' -X FUZZ -w ~/SecLists/Fuzzing/http-request-methods.txt

# recursive directory FUZZ
ffuf -c -fc 404 -u http://example.com/FUZZ -recursion -w ~/SecLists/Discovery/Web-Content/raft-medium-words.txt

# FUZZ when on different subdomain (without adding it to /etc/hosts)
ffuf -c -H 'Host: something.example.com' -w '~/SecLists/Discovery/DNS/subdomains-top1million-110000.txt' -u 'http://example.com/FUZZ'

# single IP subdomain enumeration (note that `-u` param is only for IP discovery, to enumerate subdomains on a specific IP you need to FUZZ Host header) (if you wanna enumerate DNS instead see * gobuster)
ffuf -c -H 'Host: FUZZ.example.com' -w '~/SecLists/Discovery/DNS/subdomains-top1million-110000.txt' -u 'http://example.com'

# multiple wordlists (default mode is clusterbomb (all combinations))
ffuf -c -mode pitchfork -H 'Host: SUBD.example.com' -u 'http://example.com/PATH' -w '~/wordlist_subdomain.txt:SUBD' -w '~/wordlist_path.txt:PATH' -replay-proxy 'http://127.0.0.1:8080'

# FUZZ ports in the request file
# (let's say we have a plain request from burp with a SSRF and we wanna enumerate ports)
# see [HTB Editorial]{https://youtu.be/eggi_GQo9fk?t=467}
ffuf -request ssrf.txt -request-proto http -w <(seq 1 65535)

# rate limit
ffuf -rate 20 -c -fc 404 -u http://example.com/FUZZ -w ~/SecLists/Discovery/Web-Content/raft-medium-words.txt

# forward to burp
# in burp, i add new proxy at 3333 and tell it to forward to 9595
ffuf -c -u http://localhost:3333/ # ...
```
