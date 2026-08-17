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

The command-line `Action`, `UserProfile`, and `Task` parameters are internal relaunch parameters. Normal use should go through the checklist.

## Interactive checklist

The terminal UI starts with every activity unchecked. It supports:

| Key | Action |
| --- | --- |
| `Up` / `Down` | Move the highlighted row. |
| `Space` | Check or uncheck the highlighted activity. |
| `A` | Check all activities. |
| `U` | Uncheck all activities. |
| `Enter` | Run the checked activities. |
| `Esc` | Exit without cleanup. |

The checklist exposes these activities independently:

- Windows Disk Cleanup profile
- Registry MRUs and current clipboard
- Temporary files
- Crash dumps and Windows Error Reporting files
- Explorer, shader, RDP, clipboard, and Internet caches
- PowerShell and recent-item history
- Google Chrome data
- Microsoft Edge data
- Brave data
- Mozilla Firefox data
- Recycle Bin
- DNS resolver cache
- Windows event logs
- Fixed-drive free-space cleanup

Selecting event logs still opens its separate all/minimal/cancel confirmation. Browser selections are skipped individually when the corresponding browser is running.

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
3. Shows the interactive checklist and collects the checked activity IDs.
4. Runs checked Disk Cleanup and current-user registry/clipboard activities in the elevated interactive process.
5. Validates PsExec's Microsoft signature, then sends the remaining checked activities to one `NT AUTHORITY\SYSTEM` process.
6. The SYSTEM process groups selected file categories into one pass and independently dispatches Recycle Bin, DNS, event-log, and free-space operations.
7. File deletion selects normal deletion or SDelete based on media type; free-space cleanup selects TRIM or SDelete.

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
| `$script:FileCleanupActivityIds` | File activity IDs accepted by the SYSTEM dispatcher. |
| `$script:CleanupActivities` | Ordered checklist rows and their activity IDs. |

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

# Addendum: Residual Data Exposure

The cleanup is intentionally selective. It reduces ordinary local activity history without trying to erase every forensic, recovery, security, or remote record. No in-place cleanup can prove that every copy is gone, especially on a live system.

## Selection and execution gaps

| Residual surface | Why it can remain | Supported mitigation |
| --- | --- | --- |
| Unchecked checklist activities | The TUI starts with every activity unchecked. | Review every row before execution. Use `A` only after accepting the consequences of every activity. |
| Locked or access-denied files | Normal deletion is best-effort, and some individual errors are suppressed. Explorer and Windows services can keep databases open. | Close applications, complete a Windows restart, and rerun only the relevant activities. Review warnings rather than assuming completion. |
| Running browser profiles | The script deliberately skips an entire browser when its process is running. Background mode and Edge Startup Boost can keep processes alive. | Close the browser, disable its background/startup mode temporarily, confirm its processes have exited, and rerun that browser row. |
| Interrupted cleanup | UAC cancellation, shutdown, missing tools, policy restrictions, or loss of power can leave a partial result. | Resolve the reported problem and rerun the selected activities. Do not interrupt SDelete or Disk Cleanup. |
| Event logs | Event cleanup has a separate prompt that defaults to cancellation. Individual protected logs may reject clearing, and forwarded copies are unaffected. | Clear only when permitted by the machine's audit policy. Manage retained or forwarded logs through the authorized logging system, not by deleting its files. |
| Disk Cleanup categories | `cleanmgr.exe` removes only categories enabled in profile `2504`. | Review the profile with `cleanmgr.exe /sageset:2504`. Preserve rollback, driver, or installation data that may still be needed. |
| Optional Jump Lists | Disabled by default because recent and pinned destinations share the same databases. | Enable `$script:EnableJumpListCleanup` only if losing pinned Jump List destinations is acceptable. |
| Optional ShellBags | Disabled by default because folder history and Explorer view preferences share the same keys. | Enable `$script:EnableShellBagCleanup` only if resetting folder views and layouts is acceptable. |
| Nonstandard profiles | Only configured standard browser locations and the validated portable Brave location are processed. | Add a reviewed profile root to the configuration or use that application's built-in privacy controls. Never add a broad drive or profile root. |

## Windows data intentionally retained

| Residual surface | Information it may expose | Safe way to address it |
| --- | --- | --- |
| Volume shadow copies and restore points | Earlier versions of deleted files, registry hives, browser databases, and user folders. | Keep them for recovery. If an approved retention policy requires removal, manage them separately through **System Protection** and the backup product after verifying an external backup. Do not make shadow-copy deletion part of routine cleanup. |
| File History, backup images, cloud backups, and Windows.old | Historical user files and application state. | Use each backup system's supported retention controls. For decommissioning, verify required records, expire backups according to policy, and then use Windows reset or device-erasure procedures. |
| Windows Search index | File names, content extracts, messages, and metadata from indexed locations. | Remove sensitive indexing locations or rebuild the index through **Indexing Options** after source data is removed. Rebuilding temporarily increases CPU and disk activity. |
| Notification and Connected Devices databases | Notification text, application identifiers, and cross-device activity. | Use Windows notification, clipboard, activity-history, and device-sharing settings where available. The script does not delete their live databases. |
| WebCache and broad Windows cache databases | Legacy web, account, and component state. | Use the relevant Windows or application privacy UI. Direct live-database deletion is intentionally avoided. |
| Prefetch | Names and launch patterns for executed applications. | Leave it intact on an active installation; Windows uses it for performance. For device disposal, use reset or whole-device sanitization instead of deleting Prefetch manually. |
| Amcache, AppCompat/Shimcache, SRUM, BAM/DAM, Reliability Monitor, Defender, and diagnostic telemetry | Application execution, resource use, compatibility, security, and reliability history. | Retain these security and diagnostic records. Apply organizational retention policy or use supported Windows reset/decommissioning processes; do not edit their databases directly. |
| NTFS metadata and journals | File names, timestamps, directory entries, change records, and remnants in `$MFT`, `$LogFile`, and the USN journal. | There is no safe selective in-place purge. For disposal or reassignment, use BitLocker-backed crypto-erasure, Windows **Reset this PC** with drive cleaning, or an approved whole-device sanitization process. |
| Registry transaction logs and hive copies | Older values from MRU and application-history keys. | Do not delete live transaction logs. Recovery copies disappear only through normal retention, reset, or whole-device sanitization. |
| Page file, hibernation file, crash state, and RAM | Fragments of paths, documents, browser content, credentials, and process memory. | Restart Windows after cleanup. Use supported page-file, hibernation, and shutdown policies only when their performance and feature impact is understood. Do not delete these files directly. |
| Wi-Fi profiles and network-location history | SSIDs, network names, connection properties, and remembered credentials. | Use **Settings > Network & internet** to forget networks that are no longer required. This can remove automatic connectivity and must not be automated indiscriminately. |
| Other user profiles | History and files belonging to other local or domain users. | Sign in as each authorized user and run profile-specific cleanup, or remove obsolete accounts through Windows account-management tools after backing up required data. |

## Browser and application data intentionally retained

- Firefox `places.sqlite` remains because it combines browsing history and bookmarks. Use Firefox **Clear Recent History** to clear history safely, then close Firefox before running the script.
- Bookmarks, saved passwords, extensions, permissions, custom shortcuts, HSTS state, and some site preferences remain. They can reveal sites or services used. Review them through each browser's built-in bookmark, password, extension, site-data, and profile-management pages.
- Browser synchronization can restore locally removed history or site data. Clear synchronized data through the browser account's privacy dashboard and adjust synchronization before rerunning local cleanup.
- Browser profiles outside the configured roots, other browsers, PWAs, and application-embedded web views are not covered automatically. Use their own clear-data or profile-removal controls.
- Office, Teams, Outlook, Adobe applications, media players, development tools, and other applications may keep internal recent-item lists, autosave copies, local databases, or server-side history beyond the registry keys covered here. Use each application's supported privacy and retention controls.
- WSL, Git Bash, Python, Node.js, database clients, remote-shell tools, and custom PowerShell hosts can maintain separate history files. Review them individually instead of adding broad home-directory deletion patterns.

## Network, cloud, and external records

Local DNS cache removal does not affect records held by a router, DNS or DoH provider, VPN, proxy, firewall, remote server, ISP, identity provider, Microsoft account, browser account, enterprise SIEM, EDR product, or event collector. Account sign-in, file access, web requests, and remote-session activity may therefore remain outside the computer.

Use the applicable account privacy dashboard, service retention setting, router administration process, or organizational data-retention request. A local administrator generally cannot and should not attempt to erase independently controlled audit records.

Mapped drives, NAS devices, removable media, synced folders, email attachments, exported reports, and files copied to another volume are separate copies. Address them through the owning storage or synchronization system. The selected user's Recycle Bin cleanup does not clear another user's bin or every removable/network volume.

## Storage recovery limits

- SSD deletion and TRIM are asynchronous and controlled by firmware. Wear leveling, spare blocks, controller caches, snapshots, and storage virtualization can retain data beyond the operating system's view.
- HDD SDelete processing is stronger for selected files, but filesystem metadata and copies elsewhere can remain.
- `sdelete -c 10` deliberately leaves ten percent free for live-system safety. Previously deleted, unrelated data in that reserved free space may not be overwritten.
- Unknown media types use normal deletion for selected files and skip free-space processing.
- Deduplication, Storage Spaces, virtual disks, thin provisioning, RAID, SAN snapshots, and hardware backup appliances can preserve blocks outside the selected logical volume.

Do not reduce the free-space reserve to zero on a live Windows installation merely to improve erasure coverage. For disposal, reassignment, or a requirement for high-assurance sanitization, stop using in-place selective cleanup and follow an approved offline whole-device erase or cryptographic-erasure procedure.

## Traces created by running this script

The cleanup operation itself can generate new records:

- PowerShell, UAC, CleanMgr, PsExec, SDelete, service creation, process execution, and volume-optimization activity can appear in Prefetch, Windows diagnostics, security products, event forwarding, or enterprise monitoring.
- PsExec can create the temporary `PSEXESVC` service and related service-control events. Sysinternals EULA acceptance also leaves registry state.
- The command used to launch the script can remain in the launching shell's in-memory or persisted history. A shell that remains open may rewrite its history after the script has deleted the history file.
- The script files, shortcut used to launch them, console scrollback, redirected output, terminal state, download history, filesystem timestamps, and repository history can show that the tool exists or ran.
- Clearing activity before later SYSTEM operations means those later operations can create fresh execution records after the selected MRU cleanup has completed.
- Remote event collectors and security products may receive records before local event-log cleanup occurs.

These records are intentionally not recursively erased. Keep the script in an appropriately protected administrative location, avoid redirecting output to an unprotected file, close the launching terminal after completion, and follow normal log-retention policy. If the machine is being transferred or retired, use Windows reset or approved device sanitization rather than repeatedly running the cleanup tool.

## Recommended privacy-cleanup sequence

1. Verify backups and decide which restore points, histories, pinned items, and account data must be retained.
2. Close browsers and other applications; disable browser background mode temporarily when necessary.
3. Clear Firefox history and any unsupported application's history through its own UI.
4. Pause synchronization only when doing so will not cause data loss, and address cloud-side history through the account's privacy controls.
5. Run the checklist as the intended user. Select only understood activities; event logs require separate authorization and confirmation.
6. Run free-space cleanup last and only while the machine is idle. Keep the safety reserve on a live installation.
7. Restart Windows, check for warnings or skipped browsers, and rerun only affected categories if files were previously locked.
8. Review Windows Search, notification/activity, network, backup, and browser-account settings using their supported interfaces.
9. For disposal or reassignment, stop here and use an approved full reset, crypto-erasure, or whole-device sanitization workflow.

This addendum describes known residual surfaces, not a guarantee that every third-party, firmware, cloud, enterprise, or future Windows artifact has been identified.
