# dotfiles

My Dotfiles

## documentation

see this video: [Stow has forever changed the way I manage my dotfiles](https://www.youtube.com/watch?v=y6XCebnB9gs)

- managed with [GNU Stow](https://www.gnu.org/software/stow/)

## usage

- check with `stow --simulate .`


## manual adjustments

### vi

#### nvim compatibilty

Since we're using Neovim which is using a different configuration file: Neovim typically uses init.vim located in the ~/.config/nvim/ directory, instead of .vimrc in the home directory. You can check if this directory and file exist, and if not, create them:

```bash
mkdir -p ~/.config/nvim
touch ~/.config/nvim/init.vim

ln -sf ~/.vimrc ~/.config/nvim/init.vim
```

#### install vundle

follow instructions [here](https://github.com/VundleVim/Vundle.vim).

```bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```
