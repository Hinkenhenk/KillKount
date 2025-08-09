local AddonName, ns = ...

SLASH_KILLKOUNT1 = "/kk"
SLASH_KILLKOUNT2 = "/killkount"

SlashCmdList["KILLKOUNT"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "show" or msg == "" then
        ns.GUI_Show()
    elseif msg == "hide" then
        ns.GUI_Hide()
    elseif msg == "toggle" then
        ns.GUI_Toggle()
    elseif msg == "reset" then
        ns.KK.ResetCurrentCharacter()
        ns.log("Current character data reset.")
        ns.GUI_Refresh()
    else
        print("|cff00ff00KillKount|r commands:")
        print("  /kk show    - show window")
        print("  /kk hide    - hide window")
        print("  /kk toggle  - toggle window")
        print("  /kk reset   - reset current character data")
    end
end
