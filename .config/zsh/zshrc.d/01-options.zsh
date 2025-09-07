setopt correct                                     # Auto correct mistakes
setopt autocd extendedglob                         # Extended globbing. Allows using regular expressions with *. If only directory path is entered, cd there.
setopt nocaseglob                                  # Case insensitive globbing
setopt rcexpandparam                               # Array expression with parameters
setopt nocheckjobs                                 # Don't warn about running processes when exiting
setopt numericglobsort                             # Sort filenames numerically when it makes sense
setopt appendhistory                               # Immediately append history instead of overwriting
setopt histignorealldups                           # If a new command is a duplicate, remove the older one
setopt prompt_subst                                # Enable substitution for the prompt
setopt inc_append_history                          # write as you go (per command)
setopt extended_history                            # timestamps + durations
setopt share_history                               # share across sessions
setopt hist_ignore_space                           # ignore commands starting with space
setopt hist_reduce_blanks                          # trim extra spaces
setopt hist_verify                                 # confirm !-expansion before running
setopt hist_find_no_dups                           # searching skips older dups
