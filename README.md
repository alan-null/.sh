# .sh
Linux setup script

## Usage

One liner install:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/master/install.sh)
```

## Development

#### reload tmux config
```bash
tmux source-file ~/.tmux.conf
```

#### Install from branch

```bash
export INSTALL_BRANCH=wip/multiselect
bash <(curl -fsSL https://raw.githubusercontent.com/alan-null/.sh/refs/heads/wip/multiselect/install.sh)
```
