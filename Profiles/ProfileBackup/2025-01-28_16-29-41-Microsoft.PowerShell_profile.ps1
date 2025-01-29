#
# ~~~~~~~~~~~~~
#
# Potential Themes
# To Show All Themes run Powershell Module:
#
# `Get-PoshThemes`
#
# ~~~~~~~~~~~~~
#
# Apply a new theme to test temporarily
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
#
# Where paradox is the theme name to try
#
# ~~~~~~~~~~~~~
#
# To edit a theme:
# nvim "$env:POSH_THEMES_PATH\theme_name.omp.json"
#
# ~~~~~~~~~~~~~
#
# atomic
# atomicBit
# clean-detailed
# cloud_context
# craver
# half-life
# huvix
# if_tea
# iterm2
# jblab_2021
# json
# kali
# nu4a
# powerlevel10k_modern
# powerlevel10_rainbow
# powerline
# quick-term
# robbyrussell
# slim
# space
# takuya
# tokyo
#
#
#

$env:EDITOR = "nvim"

$script:ThemeName = "$env:POSH_THEMES_PATH\atomic.omp.json"

oh-my-posh init pwsh --config "$ThemeName" | Invoke-Expression
