# swaywm-scripts

## wofipowermenu.py
Simple python3 script to present power menu with wofi.

Sway binding example:
```
bindsym $mod+Shift+e exec /usr/bin/wofipowermenu.py
```

## wofiwindowswitcher.py
Python3 script to list windows with wofi and select to focus.

Dependencies: python-gobject

Sway binding example:
```
bindsym $mod+Tab exec /usr/bin/wofiwindowswitcher.py
```

## screenshot.sh
Bash script for taking screenshots and pipe it to swappy for editing. Supports copying screenshot to clipboard or to file (xdg-user-dir PICTURES). Ability to take screenshot of whole screen, selected area or focused window

Dependencies: swappy, jq, slurp, grimp, xdg-user-dirs, wl-clipboard

Sway binding example:
```
# Take screenshot of whole screen to file
bindsym Print exec screenshot.sh
# Take screenshot of focused window to file
bindsym Alt+Print exec screenshot.sh -w
# Take screenshot of selected area to file
bindsym Shift+Print exec screenshot.sh -s

# Take screenshot of while screen to clipboard
bindsym Control+Print exec screenshot.sh -c
# Take screenshot of focused window to clipboard
bindsym Control+Alt+Print exec screenshot.sh -c -w
# Take screenshot of selected area to clipboard
bindsym Control+Shift+Print exec screenshot.sh -c -s
```
