# Parameters at the top of the script
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$Command = "Analyze", # Default command
    [string]$PermissionToExplain = "", # For explaining a specific permission
    [string]$Identity = "", # Identity for modifying permissions
    [string]$Action = "", # Action for modifying permissions (Add or Remove)
    [string]$Permissions = "" # Permissions for modifying (e.g., FullControl, Read, Write)
)

# Centralized dictionary for permission explanations
$PermissionDescriptions = @{
    "FullControl" = "Allows reading, writing, modifying, and deleting the file or folder."
    "Read" = "Allows reading file or folder contents."
    "Write" = "Allows writing data to the file or folder."
    "ReadAndExecute" = "Allows reading and executing the file or folder."
    "Synchronize" = "Allows threads to wait on the handle for the file or folder."
    "Delete" = "Allows deletion of the file or folder."
    "ReadAttributes" = "Allows reading file or folder attributes (e.g., read-only, hidden)."
    "WriteAttributes" = "Allows modifying file or folder attributes."
    "ReadPermissions" = "Allows reading permissions set on the file or folder."
    "ChangePermissions" = "Allows modifying permissions for the file or folder."
    "TakeOwnership" = "Allows taking ownership of the file or folder."
    "DeleteSubdirectoriesAndFiles" = "Allows deleting all contents, including subfolders and files."
    "ContainerInherit" = "Specifies that this ACE applies to subfolders."
    "ObjectInherit" = "Specifies that this ACE applies to files in the folder."
    "None" = "No inheritance flags set; applies only to the current object."
}

# Function: Retrieve and Explain Permissions
function Get-Permissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    Write-Host "Analyzing permissions for: $Path`n"

    # Get ACL
    $acl = Get-Acl $Path

    # Display permissions
    foreach ($entry in $acl.Access) {
        Write-Host "Identity: $($entry.IdentityReference)"
        Write-Host "Type: $($entry.AccessControlType)" # Allow or Deny
        Write-Host "Permissions: $($entry.FileSystemRights)"
        Write-Host "Inheritance: $($entry.IsInherited)" # True/False
        Write-Host "Propagation: $($entry.InheritanceFlags)" # Container/Object inherit
        Write-Host "`n"
    }
}

# Function: Explain All Permissions Found
function Explain-Permissions {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Permissions
    )

    Write-Host "Explaining permissions:`n"

    foreach ($perm in $Permissions) {
        if ($PermissionDescriptions.ContainsKey($perm)) {
            Write-Host "${perm}: $($PermissionDescriptions[$perm])`n"
        } else {
            Write-Host "${perm}: No detailed description available.`n"
        }
    }
}

# Function: Explain a Specific Permission
function Explain-SpecificPermission {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Permission
    )

    if ($PermissionDescriptions.ContainsKey($Permission)) {
        Write-Host "${Permission}: $($PermissionDescriptions[$Permission])"
    } else {
        Write-Host "${Permission}: No detailed description available."
    }
}

# Function: Simulate Inheritance for New Files
function Simulate-Inheritance {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )
    Write-Host "Simulating inheritance for new files in: $FolderPath`n"

    # Get ACL
    $acl = Get-Acl $FolderPath

    # Check inheritance rules
    foreach ($entry in $acl.Access) {
        if ($entry.InheritanceFlags -ne "None") {
            Write-Host "Inherited Permission:"
            Write-Host "Identity: $($entry.IdentityReference)"
            Write-Host "Type: $($entry.AccessControlType)"
            Write-Host "Permissions: $($entry.FileSystemRights)"
            Write-Host "`n"
        }
    }
    Write-Host "Analysis: Files created in this folder will inherit these permissions.`n"
}

# Function: Modify Permissions
function Modify-Permissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Identity,
        [Parameter(Mandatory = $true)]
        [string]$Action, # Add or Remove
        [Parameter(Mandatory = $true)]
        [string]$Permissions # e.g., "FullControl", "Read", "Write"
    )
    $acl = Get-Acl $Path

    if ($Action -eq "Add") {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity, $Permissions, "Allow")
        $acl.SetAccessRule($rule)
    } elseif ($Action -eq "Remove") {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity, $Permissions, "Allow")
        $acl.RemoveAccessRule($rule)
    }

    Set-Acl -Path $Path -AclObject $acl
    Write-Host "Permissions modified for $Path"
}

# Main Script Logic
switch ($Command) {
    "Analyze" {
        Get-Permissions -Path $Path
    }
    "Explain" {
        # Retrieve and explain all permissions found
        $acl = Get-Acl $Path
        $permissionsFound = @()

        foreach ($entry in $acl.Access) {
            $permissionsFound += $entry.FileSystemRights.ToString().Split(", ")
        }

        # Remove duplicates and explain each unique permission
        $uniquePermissions = $permissionsFound | Select-Object -Unique
        Explain-Permissions -Permissions $uniquePermissions
    }
    "ExplainSpecific" {
        # Explain a single specified permission
        if (-not $PermissionToExplain) {
            Write-Host "Please provide a specific permission to explain using -PermissionToExplain."
        } else {
            Explain-SpecificPermission -Permission $PermissionToExplain
        }
    }
    "Simulate" {
        Simulate-Inheritance -FolderPath $Path
    }
    "Modify" {
        if (-not $Identity -or -not $Action -or -not $Permissions) {
            Write-Host "Please provide all parameters: -Identity, -Action, and -Permissions."
        } else {
            Modify-Permissions -Path $Path -Identity $Identity -Action $Action -Permissions $Permissions
        }
    }
    default {
        Write-Host "Invalid command. Use 'Analyze', 'Explain', 'ExplainSpecific', 'Simulate', or 'Modify'."
    }
}
