if [[ ! $1 ]]; then
  echo Usage: ./link.sh [bin] [.vimrc] [.inputrc] ...
  echo
  echo "(Supply targets you would like to link)"
fi

SRCPATH="$(dirname "$(realpath "$0")")"

cd $HOME

for T in $@; do
  [[ -e ~/$T ]] && cp ~/$T ~/$T.own
  ln -s -i $SRCPATH/$T -T $T
done
