#Requires AutoHotkey v2

try {
    MsgBox("Starting ChangeMonitor Script...") ; Start of script

    ; Debug: Mouse Position
    MsgBox("Getting mouse position...")
    MouseGetPos(&mouseX, &mouseY)
    MsgBox("Mouse Position: " . mouseX . ", " . mouseY)

    ; Debug: Monitor Handle
    MsgBox("Getting monitor handle...")
    monitor := DllCall("MonitorFromPoint", "Int64", mouseX | (mouseY << 32), "UInt", 2, "Ptr")
    if !monitor {
        MsgBox("No monitor found for the given point.")
        return
    }
    MsgBox("Monitor Handle: " . monitor)

    ; Allocate memory for monitor info
    MsgBox("Allocating memory for monitor info...")
    monitorInfo := Buffer(40, 0) ; Allocate a 40-byte buffer
    NumPut(40, monitorInfo, 0, "UInt") ; Set the size of the structure (first 4 bytes)

    ; Retrieve monitor information
    MsgBox("Retrieving monitor information...")
    result := DllCall("GetMonitorInfoW", "Ptr", monitor, "Ptr", monitorInfo.Ptr)
    if !result {
        errorCode := A_LastError
        MsgBox("Failed to retrieve monitor information. Monitor Handle: " . monitor . " Error Code: " . errorCode)
        return
    }

    ; Extract monitor bounds
    MsgBox("Extracting monitor bounds...")
    left := NumGet(monitorInfo, 4, "Int")
    top := NumGet(monitorInfo, 8, "Int")
    right := NumGet(monitorInfo, 12, "Int")
    bottom := NumGet(monitorInfo, 16, "Int")
    MsgBox("Monitor Bounds: Left=" . left . ", Top=" . top . ", Right=" . right . ", Bottom=" . bottom)

    MsgBox("Monitor information retrieved successfully. Implement primary monitor change here.")

} catch {
    ; Error handling
    exception := Exception()
    MsgBox("Error in script: " . exception.Message . "`nLine: " . exception.Line)
}

