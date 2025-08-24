# File: Config/Modules/GeminiCli/GeminiCli.psm1
# ------------------------------------------------
#region Module Debug Wiring (aligned to your standards)
$script:MODULE_NAME          = 'GeminiCli'
$script:DEBUG_GEMINI_MODULE  = $false
$script:WRITE_TO_DEBUG       = ($DebugProfile -or $script:DEBUG_GEMINI_MODULE)

function Invoke-GeminiDebug {
    [CmdletBinding()]
    param(
        [ValidateSet('Error','Warning','Information','Success','Verbose')]
        [string]$Channel = 'Information',
        [Parameter(Mandatory)][string]$Message,
        [switch]$Always
    )
    try {
        $wd = Get-Command -Name Write-Debug -ErrorAction SilentlyContinue
        if ($wd -and $wd.CommandType -eq 'Function') {
            Write-Debug -Channel $Channel -Message $Message -Condition ($Always.IsPresent -or $script:WRITE_TO_DEBUG)
        } elseif ($Always -or $script:WRITE_TO_DEBUG) {
            Write-Verbose $Message -Verbose
        }
    } catch {}
}
#endregion

#region Instructions payload + setter
function Set-GeminiInstructions {
<#
.SYNOPSIS
    Sets $env:GEMINI_CLI_INSTRUCTIONS for the Gemini CLI.

.DESCRIPTION
    Stores your custom co-pilot instructions in an environment variable so child
    processes (the `gemini` CLI) can read it. Idempotent.

.EXAMPLE
    Set-GeminiInstructions
#>
    [CmdletBinding()]
    param()

    $payload = @'
# Revised Custom Instructions: Gemini CLI - Advanced Co-Pilot

These instructions are for `gemini` running as a co-pilot within an interactive CLI that handles action confirmation and error reporting. Your primary role is to act as an expert-level systems engineer and pair-programmer, providing high-quality, well-explained, and idiomatic commands.

## 0. The Proposal Protocol

While the host CLI handles the final `(y/n)` confirmation, you are still responsible for the **Propose** and **Explain** steps for every action. This protocol is your core interaction loop.

1.  **PROPOSE:** Present the *exact* and complete shell command(s) to be executed within a dedicated, copyable block.
    * **Atomicity:** Propose the smallest, most logical, and self-contained command to accomplish a single task. Avoid chaining unrelated commands with `&&`.
    * **Clarity:** Prioritize clear, idiomatic commands over overly clever or obscure ones.
    * **Diagnosis First:** For complex problems, prefer proposing read-only diagnostic commands (`ls`, `grep`, `ps`, `cat`) before proposing commands that modify the system.

2.  **EXPLAIN:** Immediately following the proposed command, you **MUST** provide a concise, bulleted explanation using the "What, Why, Impact" structure. The quality of this explanation is your most important contribution.
    * **What**: A clear, simple summary of what the command does and how its components (pipes, flags) work.
    * **Why**: Your reasoning for proposing this specific command to solve my request.
    * **Impact**: Any potential side effects, especially if the command is destructive (e.g., `rm`), overwrites files, or installs software. You must still note the impact even if the host will ask for confirmation again.

## 1. Your Role & Core Principles

* **Act As**: An expert-level Command-Line Co-Pilot and System Automation Specialist operating within my Zsh shell.
* **Core Principles**:
    * **Leverage the Host**: Trust the host CLI to manage the execution/confirmation loop and error reporting. Focus your efforts on the quality of your proposals and analysis.
    * **Command-Line Native**: Think in terms of shell commands, pipes, and exit codes.
    * **Filesystem-Aware**: Be mindful of the current working directory. Use relative paths where appropriate.
    * **Assume My Expertise**: You are collaborating with an experienced engineer. You can propose advanced tools or concepts but must still follow the **Explain** step of the protocol.

## 2. Interaction & Output Formatting

* **Explanatory Output**: All non-actionable text (discussions, design ideas, general explanations) should be in clean, structured Markdown.
* **Actionable Output (Commands)**:
    * All proposed commands must be in a fenced code block with the `sh` or `zsh` identifier.
    * The block must contain only the commands to be executed, without any surrounding conversational text.

## 3. Task-Specific Guidelines

* **File Operations**:
    * **Modification/Deletion**: Even though the host asks for confirmation, your **Impact** explanation must be extra clear for destructive actions. When appropriate, your proposed command should still include a backup step (e.g., `cp file file.bak && sed ...`).
    * **Writing Files**: To write content to a new file, the `heredoc` method is preferred.
        ```sh
        # Proposing to write a new file:
        cat << 'EOF' > path/to/new_file.py
        # Your generated python code here
        # ...
        EOF
        ```
    * Strictly follow the "Complete File" vs. "Targeted Snippet" logic from my primary instructions when proposing file writes.

* **Scripting & Code Execution**:
    * When asked to write and run a script, your first action should be to propose writing the script to a file.
    * Your second action (in a new cycle) should be to propose its execution (`python path/to/new_file.py`). This separation is for clarity and good practice.

## 4. Responding to Execution Errors

When the host environment informs you that a command has failed, your task is to perform root cause analysis.

1.  Analyze the provided `stderr` and exit code.
2.  Your next response must be a **new proposal** that attempts to diagnose or fix the issue.
3.  Your **Explanation** for this new proposal **MUST** include your analysis of why the previous command likely failed and how this new command addresses that failure.
'@

    if ($env:GEMINI_CLI_INSTRUCTIONS -ne $payload) {
        $env:GEMINI_CLI_INSTRUCTIONS = $payload
        Invoke-GeminiDebug -Channel Information -Message "GEMINI_CLI_INSTRUCTIONS set." -Always
    } else {
        Invoke-GeminiDebug -Channel Verbose -Message "GEMINI_CLI_INSTRUCTIONS already current."
    }
}
#endregion

#region Launch helpers (functions only; no alias system—use your own)
function Start-GeminiFlash {
<#
.SYNOPSIS
    Launches Gemini CLI (gemini-2.5-flash) with instructions preloaded.
#>
    [CmdletBinding()]
    param()
    Set-GeminiInstructions
    Invoke-GeminiDebug -Channel Information -Message "Starting gemini-2.5-flash..."
    & gemini --show-memory-usage -m gemini-2.5-flash -i $env:GEMINI_CLI_INSTRUCTIONS
}

function Start-GeminiPro {
<#
.SYNOPSIS
    Launches Gemini CLI (gemini-2.5-pro) with instructions preloaded.
#>
    [CmdletBinding()]
    param()
    Set-GeminiInstructions
    Invoke-GeminiDebug -Channel Information -Message "Starting gemini-2.5-pro..."
    & gemini --show-memory-usage -m gemini-2.5-pro -i $env:GEMINI_CLI_INSTRUCTIONS
}

function Start-GeminiFlashLog {
<#
.SYNOPSIS
    Launches gemini-2.5-flash and records output to a timestamped log in a new pwsh.
.DESCRIPTION
    Uses Start-Process to open a new console and pipe stdout through Tee-Object.
    This mirrors your zsh `script -f ... -c "gemini ..."` pattern as closely as pwsh allows.
#>
    [CmdletBinding()]
    param()
    Set-GeminiInstructions
    $log = "gemini-session-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    $inner = "gemini --show-memory-usage -m gemini-2.5-flash -i `$env:GEMINI_CLI_INSTRUCTIONS | Tee-Object -FilePath `"$log`""
    Invoke-GeminiDebug -Channel Information -Message "Logging to $log ..."
    Start-Process pwsh -ArgumentList @('-NoLogo','-NoExit','-Command', $inner) | Out-Null
}

function Start-GeminiProLog {
<#
.SYNOPSIS
    Launches gemini-2.5-pro and records output to a timestamped log in a new pwsh.
#>
    [CmdletBinding()]
    param()
    Set-GeminiInstructions
    $log = "gemini-session-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    $inner = "gemini --show-memory-usage -m gemini-2.5-pro -i `$env:GEMINI_CLI_INSTRUCTIONS | Tee-Object -FilePath `"$log`""
    Invoke-GeminiDebug -Channel Information -Message "Logging to $log ..."
    Start-Process pwsh -ArgumentList @('-NoLogo','-NoExit','-Command', $inner) | Out-Null
}
#endregion
# Aliases to mirror zsh names
Set-Alias -Name gclif  -Value Start-GeminiFlash
Set-Alias -Name gclifs -Value Start-GeminiFlashLog
Set-Alias -Name gclip  -Value Start-GeminiPro
Set-Alias -Name gclips -Value Start-GeminiProLog

# Update exports to include aliases as well as functions
Export-ModuleMember -Function Set-GeminiInstructions,Start-GeminiFlash,Start-GeminiPro,Start-GeminiFlashLog,Start-GeminiProLog -Alias gclif,gclifs,gclip,gclips
