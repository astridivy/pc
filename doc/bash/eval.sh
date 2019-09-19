# misguided attempt at setting environment variables
setadd_old () {
  local SETNAME="$1"
  local SETREF="\$$SETNAME"
  local SET=`eval echo $SETREF`

  local VALUE="$2"

  if [[ ! $SET ]]; then
    eval $SETNAME=$VALUE
  elif [[ $SET != *$VALUE* ]]; then
    eval $SETNAME="$SETREF:$VALUE"
  fi
}
