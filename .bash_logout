#
# ~/.bash_logout
#
# (pc/.bash_logout)
#

# the other half of the screen dance in bashrc/screen: detach instead of
# tearing the session down, so the next login picks up mid-sentence.
# this file is the hook because ~/.bash_logout is a path only bash reads,
# and bashrc has no way to reach it
command -v screen_dance_out >/dev/null && screen_dance_out

# has to be 0, and has to be last: logging out is not an error, and
# whatever the dance leaves in $? would otherwise become ssh's exit status
exit 0
