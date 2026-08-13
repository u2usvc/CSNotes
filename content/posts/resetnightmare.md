---
title: "ResetNightmare traces"
date: 2026-08-13
description: "Detection for CVE-2026-27912 (ResetNightmare) in Kerberos kpasswd password reset mechanism and possibly UPN confusion"
---

## Vulnerability description

- Affected: Kerberos. Tested on Windows Server 2022 build 20348
- Prerequisites: unprivileged account credentials, ability to change UPN attribute value of an account you control
- Impact: set password for any domain account
- PoC: <https://github.com/Semperis-Community/ResetNightmare>

The attack flow is described within the attached PoC README.

`UserPrincipalName` must be set to a target account, this might not be an Administrator account necessarily, but any potential target account.
After ST is obtained, it is used within the kpasswd protocol password change request. It uses it's own 464 port.

First thought, an ST (via AS-REQ) request (4768) where `SamAccountName` does not match `UserPrincipalName` and `sname` set to `kadmin/changepw` SPN, which corresponds to Kerberos password change service, which is an alternative password change mechanism to MS-SAMR.

Yes, AS-REQ is used to request an ST, because in essence, TGT is just an ST to `krbtgt`, so I am gonna call it an ST to `kadmin/changepw`.

However, we need to remember that because `sname` within the Kerberos ticket is located outside of the `encTicketPart`, an attacker may change it **offline** without the need to know the service kerberos key.
That is why we cannot base our detection on the contents of `sname`.
And in fact, when I observed this attack on the SIEM side, all STs had `krbtgt` as its `service.name`.

Next thought was, what if we could somehow detect the mismatch between the UPN `cname` (`winlog.event_data.TargetUserName`) and the actual SAN of an account requesting the ST? However I observed that there is nothing pointing to the resolved account's UPN within the 4768 event.

So we have multiple options:

- 5136 (AD object is modified): detect UPN change
- 4723 (An attempt was made to change an account's password): detect password change

First of all, a detection can be based on the fact that machine account is used (e.g. machine account changing other account's password or machine account UPN set), however what if an attacker has `GenericWrite` against a user account?

I actually got an interesting idea out of this, if we observe the PoC we can see that it puts a `TargetAccount` SAN in controlled account's UPN.

![UPN change](/images/rstnghm-code01.png)

The thing about UPNs is that they are formatted as `user@domain.lab` and SANs are formatted as `User`. So we can make a single detection rule that detects a change to UPN attribute value not containing `@` suffix or having this suffix in the end of the string.
I did actually test this PoC with the `@` suffix under UPN and it doesn't work, I cannot think of any way to bypass this.

Additionally, the UPN mismatch really reminds me of UPN confusion attack against Linux SSSD (which I, honestly, haven't tested) and it would not be a surprise if this rule catches it as well.

## Testing the PoC

Considering I control and may change the UPN attribute value of `c00l4cc` machine account and know its password:

![Invoke-ResetNightmare](/images/invoke-resetnightmare.png)

secretsdump succeeds with new credentials:

![secretsdump](/images/rstnghm-test01.png)

Quick look at the incoming events:

![Elastic](/images/rstnghm-detect01.png)

## Detection rules

Flawed UPN format AD object update:

```yaml
title: UPN written without a domain suffix
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 5136
    AttributeLDAPDisplayName: 'userPrincipalName'
  suffix_empty:
    AttributeValue|endswith: '@'
  filter_has_suffix:
    AttributeValue|contains: '@'
  condition: selection and (suffix_empty or not filter_has_suffix)
```
