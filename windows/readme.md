# Windows 11 Cleanup Tool

`cleanup.ps1` is an interactive Windows 11 cleanup script. It combines Windows Disk Cleanup with targeted user-activity cleanup, Windows event-log clearing, and media-aware deleted-data cleanup.

> **Warning:** Cleanup is irreversible. Review the configured paths before running the script. Close browsers, Office applications, Windows Terminal, Remote Desktop, and other applications first so that their databases are not locked. Use this only on a Windows installation that you own or administer.

This is a privacy and maintenance tool, not a guarantee of forensic erasure. SSD wear leveling, synchronization services, backups, shadow copies, remote services, and files that remain locked can retain data outside the script's control.

## Requirements

- Windows 11
- PowerShell 7 (`pwsh`)
- An account with local administrator rights
- An official, Microsoft-signed [Sysinternals PsExec](https://learn.microsoft.com/sysinternals/downloads/psexec) available in `PATH`
- An official, Microsoft-signed [Sysinternals SDelete](https://learn.microsoft.com/sysinternals/downloads/sdelete) available in `PATH` as `sdelete.exe`
- The built-in `cleanmgr.exe`, storage, DNS, and volume-management commands

PowerShell 7 is recommended because the elevation code uses the modern `ProcessStartInfo.ArgumentList` API.

## Preparation

### 1. Configure Disk Cleanup

The script uses Disk Cleanup profile `2504`. Configure it once from an elevated terminal:

```powershell
cleanmgr.exe /sageset:2504
```

Select the Windows cleanup categories that should be removed. The script later runs that saved selection with `/sagerun:2504`.

### 2. Install the Sysinternals tools

Place `PsExec.exe` and `SDelete.exe` from the official Sysinternals downloads in a trusted directory listed in `PATH`. Before elevation through PsExec or deletion through SDelete, the script requires a valid Authenticode signature issued to Microsoft Corporation. This prevents an untrusted same-named executable earlier in `PATH` from running as administrator or SYSTEM. The script accepts both tools' EULAs automatically when it invokes them.

### 3. Close applications

At minimum, close Chromium browsers, Firefox, Office, PowerShell/Windows Terminal, Remote Desktop, and Explorer windows that are using recent files. Locked SQLite databases and cache files are deleted on a best-effort basis and may otherwise be skipped.

## Running the script

From this directory:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\cleanup.ps1
```

Approve the UAC prompt with the same Windows account that launched the script. The original profile path is retained across elevation, while current-user registry cleanup operates on the elevated account's `HKCU` hive.

The command-line `Action`, `UserProfile`, and `Task` parameters are internal relaunch parameters. Normal use should go through the menu.

## Menu

| Choice | Operation |
| --- | --- |
| `1` | Runs the saved Disk Cleanup profile. |
| `2` | Clears current-user activity, configured files and caches, the selected profile's Recycle Bin, and DNS cache. |
| `3` | Clears Windows event logs. |
| `4` | Retrims SSD free space and wipes HDD free space. |
| `A` | Runs all operations in the order shown below. |

## What is cleaned

### Disk Cleanup

`cleanmgr.exe /sagerun:2504` removes only the Windows categories selected when `/sageset:2504` was configured. This can include Windows Update files, temporary setup files, delivery optimization files, and other built-in categories.

### Windows and profile files

The file-cleanup task covers:

- The SYSTEM and selected user's temporary directories
- Windows and per-user crash dumps
- Windows Error Reporting archives, queues, and temporary reports
- Direct3D shader cache
- Explorer icon and thumbnail caches
- Legacy Internet cache data
- Clipboard-history files
- PowerShell PSReadLine command-history files
- Recent-item shortcuts
- Remote Desktop bitmap cache

Windows recreates these cache directories and files. Clearing shader and icon caches can make the first launch of applications temporarily slower. Prefetch, Connected Devices activity databases, the live notification database, the broad Windows cache directory, and WebCache are deliberately left intact because deleting them from a running session can affect performance or leave live database services in an inconsistent state.

### Browser data

For every discovered profile under the standard installation locations, the script removes:

- Google Chrome cache, code cache, GPU cache, service workers, browsing and download history, favicons, URL prediction data, top sites, and visited-link data
- Microsoft Edge equivalents
- Brave equivalents
- Chromium cookies, site storage, IndexedDB, Privacy Sandbox interest/topic data, bounce-tracking state, media history, trust tokens, site-characteristics data, network-origin state, and current/recent session files
- Firefox disk/startup caches, thumbnails, cookies, favicons, form history, tracker-protection statistics, bounce-tracking state, site storage indexes/data, network alternative-service cache, device-enumeration salts, and session-restore data

The configured portable Brave profile under `F:\Browsers\Brave\Default\Default` receives equivalent Chromium cleanup only when its `Preferences` profile marker exists. Update `$script:PortableBraveProfileRoot` if that profile is stored elsewhere. This marker check prevents a stale drive letter from turning an unrelated directory into a cleanup target.

This cleanup signs websites out, removes offline website data, and prevents restoration of previously open browser tabs. Saved passwords, bookmarks, extensions, custom new-tab shortcuts, and HSTS transport-security state are preserved. If a browser process is running, all cleanup for that browser is skipped rather than risking partial deletion of a live database; close its background processes and rerun the task. Firefox browsing history is stored with bookmarks in `places.sqlite`; it is not deleted because removing that database would risk bookmark loss. Use Firefox's built-in **Clear Recent History** feature when Firefox history must also be removed.

### Current-user registry activity

The script removes keys that Windows or applications recreate as needed, including:

- Run dialog, Explorer address-bar, and Windows search terms
- Recent documents and common file-dialog MRUs
- UserAssist application-launch history and Explorer feature-use history
- Recent/mounted drive and mapped-network-drive history
- Remote Desktop server and username history
- Paint, Windows Media Player, and legacy Internet Explorer recent/typed lists
- Application Compatibility Assistant execution history
- Office file, place, and per-user MRU lists

This also clears the current clipboard. Pinned taskbar and Start menu items are not removed.

ShellBag keys can reveal previously browsed folders but also store Explorer folder-view preferences. They are preserved by default. Enabling `$script:EnableShellBagCleanup` removes that metadata and resets folder layouts, view modes, sorting, and window preferences to Windows defaults; it does not remove files or folders.

### Recycle Bin and DNS

The script resolves the selected profile to its Windows SID and removes only that SID's Recycle Bin content from fixed volumes. It also clears the machine-wide DNS client resolver cache.

### Event logs

By default, `$script:EnableEventLogsChoice` is `$true`, so the event-log task asks before clearing logs and defaults to cancellation. The prompt offers all logs, only `Application`, `Security`, `Setup`, and `System`, or cancellation. Edit `$script:MinimalEventLogs` to change that subset.

Setting the option to `$false` suppresses the prompt and clears **all** enumerated Windows event logs. This removes operational, diagnostic, and security audit records and may be restricted by policy.

### Deleted-data handling

Each configured path is mapped to its physical disk:

- **SSD:** normal deletion is used. The free-space task then calls `Optimize-Volume -ReTrim`.
- **HDD:** SDelete recursively removes configured paths. The free-space task later runs `sdelete -c 10` on the fixed volume, reserving 10 percent free space for the running system.
- **Unknown media:** normal deletion is used for files; free-space processing is skipped to avoid applying the wrong operation.

TRIM tells an SSD that blocks are unused, but it does not guarantee immediate physical erasure because SSD firmware controls garbage collection and wear leveling. SDelete free-space processing can take a long time and creates substantial temporary disk activity. The configured reserve reduces disk-full risk but does not eliminate the performance impact; run it while the machine is otherwise idle.

Before recursive SDelete operations, the script checks for reparse points such as junctions and symbolic links. If one is found, it uses PowerShell's normal non-following deletion instead, preventing a user-writable link from redirecting SYSTEM-level deletion outside the intended cache.

## Execution and privilege model

The script follows this sequence:

1. Captures the interactive user's profile path.
2. Restarts itself through UAC as administrator.
3. Shows the menu.
4. Performs current-user registry and clipboard cleanup only if the elevated `HKCU` profile matches the captured target profile.
5. Validates PsExec's Microsoft signature, then starts the file, event-log, and free-space tasks as `NT AUTHORITY\SYSTEM` in the current session.
6. Selects normal deletion, SDelete, or TRIM based on the physical media type.

Running privileged tasks as SYSTEM allows access to protected cache locations while retaining the originally captured user profile for profile-specific paths.

## Configuration

The main settings are at the top of `cleanup.ps1`:

| Setting | Purpose |
| --- | --- |
| `$script:EnableEventLogsChoice` | Enables the all/minimal/cancel event-log prompt. |
| `$script:EnableJumpListCleanup` | Clears Jump List databases when enabled; disabled to preserve pinned destinations. |
| `$script:EnableShellBagCleanup` | Clears folder-navigation metadata when enabled; disabled to preserve Explorer view settings. |
| `$script:CleanMgrProfile` | Disk Cleanup profile number. |
| `$script:SDeletePath` | SDelete executable name or path. |
| `$script:SDeleteFreeSpaceReservePercent` | Percentage left free during HDD free-space cleaning. |
| `$script:MinimalEventLogs` | Logs used by the minimal event-log option. |
| `$script:CleanupPathTemplates` | Windows, profile, and Firefox targets; `{UserProfile}` is replaced before execution. |
| `$script:ChromiumProfileRoots` | Standard Chromium profile roots and any validated portable root. |
| `$script:PortableBraveProfileRoot` | Portable Brave root, enabled only when its `Preferences` marker exists. |
| `$script:ChromiumActivityPaths` | Relative Chromium cache, history, site-data, and session targets. |
| `$script:UserActivityRegistryPaths` | Current-user registry history targets. |

A cleanup path ending in `*` removes its contents while leaving the parent directory available for Windows or the application to reuse. Missing paths are reported and skipped.

Jump List databases mix activity history with user-pinned destinations. They are preserved by default. Set `$script:EnableJumpListCleanup` to `$true` only if removing both recent and pinned Jump List entries is acceptable.

ShellBag history mixes folder-navigation metadata with Explorer layout preferences. Set `$script:EnableShellBagCleanup` to `$true` only if resetting those preferences is acceptable.

## Deliberate exclusions and limitations

To avoid damaging Windows or deleting credentials and user content, the script does not remove:

- Browser saved passwords, bookmarks, or extensions
- Firefox `places.sqlite`
- Windows restore points, volume shadow copies, backups, or File History
- Prefetch and live Connected Devices activity, Windows notification, WebCache, and broad system-cache databases
- The page file, hibernation file, registry transaction logs, or NTFS USN journal
- Defender protection history, Amcache, SRUM, BAM/DAM, or other protected security/system databases
- Windows Search indexes, NTFS forensic structures, Wi-Fi profiles, or network-location profiles
- Cloud-side Microsoft activity, browser synchronization data, DNS provider logs, router logs, or enterprise audit systems
- Shell histories for WSL, Python, Node.js, Git Bash, or third-party tools

Event logs, Recycle Bin content, browser history, recent-item metadata, and command history can be operationally useful. Back up anything needed before cleanup.

## Validation

A syntax-only check can be run without executing cleanup:

```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path '.\cleanup.ps1'),
    [ref]$null,
    [ref]$errors
)
$errors
```

No output from `$errors` means the parser found no PowerShell syntax errors.
