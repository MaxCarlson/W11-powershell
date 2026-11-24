# Terminal session identity

`CustomProfile.ps1` initializes a general PowerShell session identity for interactive shells. Any child program can read these process environment variables:

- `TERMINAL_SESSION_ID`: a UUID for this PowerShell process and its profile session.
- `TERMINAL_SESSION_OWNER_PID`: the PID of the PowerShell process that initialized the identity. This is diagnostic metadata.

The profile sources `Initialize-TerminalSessionIdentity.ps1` after its existing automation-shell early return. The helper creates a UUID with .NET, sets both values only in the current process environment, and keeps a global PowerShell state marker so sourcing it again in the same shell retains the UUID and owner PID. A child PowerShell process inherits the environment values but not the PowerShell global marker, so it creates a new identity. Other native child processes inherit the values through normal process environment inheritance.

Initialization is independent of LLMD or any other installed program. It performs no network access or persistent filesystem writes. It does not change the prompt, machine or user environment, profile bootstrap, or module-loading behavior. Automation and noninteractive shells still return before the helper is sourced.

## Initialize an already-open shell

Run this once in the shell (adjust the repository path if it is elsewhere):

```powershell
. "$HOME\src\W11-powershell\Profiles\Initialize-TerminalSessionIdentity.ps1"
```

The command can be repeated safely; it retains the current shell's identity. Check the values with:

```powershell
$env:TERMINAL_SESSION_ID
$env:TERMINAL_SESSION_OWNER_PID
```

## Troubleshooting

- If either variable is empty, source the helper in the current shell or start a new interactive PowerShell session.
- The profile intentionally skips initialization in automation and noninteractive shells.
- A nested PowerShell process receives a new ID by design, even though it inherits the parent's environment. Native programs launched from one shell keep that shell's ID.
- `TERMINAL_SESSION_OWNER_PID` should match `$PID` in the shell that initialized it. It identifies the originating PowerShell process, not the terminal application's window process.
