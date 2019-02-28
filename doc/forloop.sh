      for (( expr1 ; expr2 ; expr3 )) ; do list ; done
              First, the arithmetic expression expr1 is evaluated according to the
              rules  described  below under ARITHMETIC EVALUATION.  The arithmetic
              expression expr2 is then evaluated repeatedly until it evaluates  to
              zero.   Each  time expr2 evaluates to a non-zero value, list is exe‐
              cuted and the arithmetic expression  expr3  is  evaluated.   If  any
              expression  is  omitted,  it  behaves  as if it evaluates to 1.  The
              return value is the exit status of the last command in list that  is
              executed, or false if any of the expressions is invalid.

       select name [ in word ] ; do list ; done
              The  list  of  words  following in is expanded, generating a list of
              items.  The set of expanded words is printed on the standard  error,
              each  preceded  by  a  number.  If the in word is omitted, the posi‐
              tional parameters are  printed  (see  PARAMETERS  below).   The  PS3
              prompt  is  then  displayed and a line read from the standard input.
              If the line consists of a number corresponding to one  of  the  dis‐
              played  words,  then  the value of name is set to that word.  If the
              line is empty, the words and prompt are displayed again.  If EOF  is
              read, the command completes.  Any other value read causes name to be
              set to null.  The line read is saved in  the  variable  REPLY.   The
              list  is executed after each selection until a break command is exe‐
              cuted.  The exit status of select is the exit  status  of  the  last
              command executed in list, or zero if no commands were executed.

       case word in [ [(] pattern [ | pattern ] ... ) list ;; ] ... esac
              A  case  command  first  expands word, and tries to match it against
              each pattern in turn, using the same matching rules as for  pathname
              expansion  (see  Pathname  Expansion  below).   The word is expanded
              using tilde expansion, parameter and variable expansion,  arithmetic
              expansion,  command  substitution,  process  substitution  and quote
              removal.  Each pattern examined is expanded using  tilde  expansion,
              parameter and variable expansion, arithmetic expansion, command sub‐
              stitution, and  process  substitution.   If  the  nocasematch  shell
              option is enabled, the match is performed without regard to the case
              of alphabetic characters.  When a match is found, the  corresponding
              list is executed.  If the ;; operator is used, no subsequent matches
              are attempted after the first pattern match.  Using ;& in  place  of
              ;;  causes  execution  to continue with the list associated with the
              next set of patterns.  Using ;;& in place of ;; causes the shell  to
              test the next pattern list in the statement, if any, and execute any
              associated list on a successful match.  The exit status is  zero  if
              no  pattern  matches.   Otherwise, it is the exit status of the last
              command executed in list.

