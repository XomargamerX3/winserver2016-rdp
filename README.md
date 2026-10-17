# Windows Server 2016 - RDP + full control on Oracle Cloud

سيرفر Windows Server 2016 بـ RDP وبتحكم كامل على Oracle Cloud، مع ملف تأمين RDP
وسكربتات تنصيب وتشغيل سيرفر لعبة CS 1.6 جوّه السيرفر.

## الباسوردات
مفيش أي باسورد مكتوب في الرّيبو ده. ولّد ٣ باسوردات قوية انت:

```powershell
$a='ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
-join (1..18|%{$a[(Get-Random -Maximum $a.Length)]})
```

واحد لحساب Oracle (لوحة التحكم) + واحد لحساب srvadmin جوّه السيرفر + واحد لـ rcon.
احتفظ بيهم في ملف نصي عندك ومتكتبهوش في أي مكان عام.

## اختيار المقاس (Shape)
| المقاس | RAM | ويندوز | ينفع سيرفر لعبة؟ |
|---|---|---|---|
| VM.Standard.E2.1.Micro (مجاني) | 1 GB | BYOL | لا - 1GB ما تكفيش |
| Ampere A1 (مجاني) | 12 GB | ARM: ما بيدّش Windows | - |
| VM.Standard.E4.Flex, 1 OCPU | 8 GB | نعم | نعم (من كريدت ٣٠٠$) |

## الترتيب
1. `https://signup.cloud.oracle.com` - Home Region: **Frankfurt** او **Ashburn** + فيزا للتوثيق.
2. Compute -> Create instance -> **Windows Server 2016/2019 (BYOL)** - shape E4.Flex 1 OCPU / 8GB.
3. VCN -> Security List -> افتح البورتات من الجدول تحت.
4. `mstsc` -> الـ Public IP بتاع الـ instance.
5. PowerShell (Admin) جوّه السيرفر: `server/harden-rdp.ps1` -> **سيب جلسة RDP مفتوحة وهو شغال**.
6. `game/install-game-server.bat` ثم `game/run-server-online.bat`.
7. قَيّد قاعدة 3389 على IP بيتك (`1.2.3.4/32`) بدل `0.0.0.0/0`.

## قواعد Oracle اللي لازم تفتحها (Security List - Ingress)
| Source | IP Protocol | Port | الغرض |
|---|---|---|---|
| 0.0.0.0/0 (قيّدها بعدين) | TCP | 3389 | RDP |
| 0.0.0.0/0 | UDP | 27015 | سيرفر CS 1.6 |
| 0.0.0.0/0 | TCP | 27015 | سيرفر |
| 0.0.0.0/0 | UDP | 27016 | عملاء اللعبة |
| 0.0.0.0/0 | TCP | 27020 | HLTV |

Oracle فيه ناروالين: ناروال الويندوز + Security List في السحابة. لو RDP ما جاش، المشكلة
من السحابة في 90% من الحالات مش من الويندوز.

## ملاحظات Oracle
- instances الـ Always Free **الخاملة بتسترجعها Oracle** - حط scheduled job يخليها نشطة.
- مقاس 8GB بيتحاسب من كريدت ٣٠٠$ (٣٠ يوم) - بعدها اما PAYG او نزّل للمقاس المجاني.
- لو IP بيتك بيتغير: Tailscale / WireGuard احسن بكتير من سيّب 3389 مفتوح للكل.

## الملفات
| الملف | الغرض |
|---|---|
| `server/harden-rdp.ps1` | NLA + SSL + lockout + حجب حساب Administrator المدمج + Defender |
| `answerfile/autounattend.xml` | تنصيب اوتوماتيك لو جبت سيرفر ويندوز تاني (Hyper-V / VPS) |
| `game/install-game-server.bat` | تحميل وتنصيب HLDS جوّه السيرفر |
| `game/run-server-local.bat` | تشغيل السيرفر محليًا (sv_lan 1) |
| `game/run-server-online.bat` | تشغيل السيرفر للعب مع الأصحاب |
| `docs/security.md` | قائمة مراجعة الأمان |

## تحذير
سيرفر ويندوز مفتوح على الإنترنت بيتعمل له brute force في دقايق.
`server/harden-rdp.ps1` مش اختيارية.
