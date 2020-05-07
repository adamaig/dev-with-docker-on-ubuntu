# Clipboard Support

For Mac, in order to use the clipboard across the host and the guest vagrant box, you must:

1. Download and run [XQuartz](https://www.xquartz.org/)
1. Forward X11 in your ssh connection:

```shell
  Host localhost
    ...
    ForwardX11 yes
```

or pass the `-X` flag to the ssh connection string

`ssh user@host -X`

## Add Support for `pbcopy` and `pbpaste`

If you prefer to use `pbcopy` and `pbpaste` within the vagrant box just add the following to your shell config.

```shell
# .zshrc or .bashrc
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
```

## Add Clipboard Support to Tmux

```shell
# .tmux.conf
if-shell "uname -n | grep vagrant" \
  'bind-key -t vi-copy Enter copy-pipe "xclip -in -selection clipboard"'
```
