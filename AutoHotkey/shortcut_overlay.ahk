; Define the shortcut overlay hotkey (Ctrl + Shift + H)
^+h::
{
    ; If the overlay is already displayed, destroy it
    if (OverlayGui) {
        OverlayGui.Destroy()
        OverlayGui := ""
        return
    }

    ; Create the dim background
    OverlayGui := Gui("+AlwaysOnTop -Caption +E0x20") ; Transparent GUI
    OverlayGui.BackColor := "Black"
    OverlayGui.Transparent := 150 ; Set transparency for dimming effect
    ScreenWidth := A_ScreenWidth
    ScreenHeight := A_ScreenHeight
    OverlayGui.Show("x0 y0 w" ScreenWidth " h" ScreenHeight)

    ; Define shortcut details
    Shortcuts := [
        {Key: "Win + E", Desc: "Open Explorer", X: 100, Y: 200},
        {Key: "Alt + Tab", Desc: "Switch Windows", X: 100, Y: 300},
        {Key: "Ctrl + Shift + H", Desc: "Show this overlay", X: 100, Y: 400}
    ]

    ; Loop through shortcuts and create stylized blocks
    for index, shortcut in Shortcuts {
        BlockGui := Gui("+AlwaysOnTop -Caption")
        BlockGui.BackColor := "Blue" ; Block background color
        BlockGui.Show("x" shortcut.X " y" shortcut.Y " w200 h50") ; Block dimensions

        ; Add the key text inside the block
        BlockGui.Font("s14 Bold", "Segoe UI")
        BlockGui.AddText("Center cWhite", shortcut.Key)

        ; Add the description below the block
        DescGui := Gui("+AlwaysOnTop -Caption +E0x20")
        DescGui.Font("s10", "Segoe UI")
        DescGui.AddText("Center cWhite", shortcut.Desc)
        DescGui.Show("x" shortcut.X " y" shortcut.Y + 60 " w200 h30")
    }

    return
}

