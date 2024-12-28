function Get-HelpFlag {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PassedArgs
    )

    $helpAliases = @("--help", "-h", "-?")
    foreach ($alias in $helpAliases) {
        if ($PassedArgs[$alias] -eq $true) {
            Show-HelpMessage
            return $true
        }
    }
    return $false
}

function Show-HelpMessage {
    $helpMessage = @"
Manage-SymbolicLinks

Creates or deletes symbolic links and hardlinks for files/folders.

Parameters:
  -SourcePaths        A single source file/folder or a list of files/folders.
                      Required for creating or deleting links.
  -DestinationFolder  The folder where symbolic links should be created.
                      Required for creating links.
  -LinkNames          (Optional) Custom names for the symbolic links.
                      If not provided, the source names are used.
  -LinkType           (Optional) Specify 'file', 'directory', or 'auto' (default: auto).
  -DeleteLinks        (Optional) Deletes the specified links in SourcePaths.
                      Does not remove the original data.

Examples:
  Create Symbolic Links:
    Manage-SymbolicLinks -SourcePaths "C:\anime\Show1" -DestinationFolder "C:\TopAnime"

  Delete Symbolic Links:
    Manage-SymbolicLinks -SourcePaths "C:\TopAnime\Show1" -DeleteLinks

  With Custom Names:
    Manage-SymbolicLinks -SourcePaths "C:\anime\Show1" -DestinationFolder "C:\TopAnime" -LinkNames "CustomName"
"@
    Write-Host $helpMessage
}
