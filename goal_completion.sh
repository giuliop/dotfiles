# bash completion for goal                                 -*- shell-script -*-

__goal_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__goal_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__goal_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__goal_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__goal_handle_reply()
{
    __goal_debug "${FUNCNAME[0]}"
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            COMPREPLY=( $(compgen -W "${allflags[*]}" -- "$cur") )
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __goal_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __goal_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        COMPREPLY=( $(compgen -W "${noun_aliases[*]}" -- "$cur") )
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        declare -F __custom_func >/dev/null && __custom_func
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__goal_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__goal_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1
}

__goal_handle_flag()
{
    __goal_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __goal_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __goal_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __goal_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if __goal_contains_word "${words[c]}" "${two_word_flags[@]}"; then
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__goal_handle_noun()
{
    __goal_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __goal_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __goal_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__goal_handle_command()
{
    __goal_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_goal_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __goal_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__goal_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __goal_handle_reply
        return
    fi
    __goal_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __goal_handle_flag
    elif __goal_contains_word "${words[c]}" "${commands[@]}"; then
        __goal_handle_command
    elif [[ $c -eq 0 ]]; then
        __goal_handle_command
    elif __goal_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __goal_handle_command
        else
            __goal_handle_noun
        fi
    else
        __goal_handle_noun
    fi
    __goal_handle_word
}

_goal_account_addpartkey()
{
    last_command="goal_account_addpartkey"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--keyDilution=")
    local_nonpersistent_flags+=("--keyDilution=")
    flags+=("--outdir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outdir=")
    flags+=("--roundFirstValid=")
    local_nonpersistent_flags+=("--roundFirstValid=")
    flags+=("--roundLastValid=")
    local_nonpersistent_flags+=("--roundLastValid=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_flag+=("--roundFirstValid=")
    must_have_one_flag+=("--roundLastValid=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_balance()
{
    last_command="goal_account_balance"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_changeonlinestatus()
{
    last_command="goal_account_changeonlinestatus"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--fee=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--online")
    flags+=("-o")
    local_nonpersistent_flags+=("--online")
    flags+=("--partkeyfile=")
    local_nonpersistent_flags+=("--partkeyfile=")
    flags+=("--txfile=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--txfile=")
    flags+=("--validrounds=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_delete()
{
    last_command="goal_account_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_dump()
{
    last_command="goal_account_dump"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_export()
{
    last_command="goal_account_export"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_import()
{
    last_command="goal_account_import"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--default")
    flags+=("-f")
    local_nonpersistent_flags+=("--default")
    flags+=("--mnemonic=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--mnemonic=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_importrootkey()
{
    last_command="goal_account_importrootkey"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--unencrypted-wallet")
    flags+=("-u")
    local_nonpersistent_flags+=("--unencrypted-wallet")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_info()
{
    last_command="goal_account_info"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_installpartkey()
{
    last_command="goal_account_installpartkey"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--delete-input")
    local_nonpersistent_flags+=("--delete-input")
    flags+=("--partkey=")
    local_nonpersistent_flags+=("--partkey=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--partkey=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_list()
{
    last_command="goal_account_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--info")
    local_nonpersistent_flags+=("--info")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_listpartkeys()
{
    last_command="goal_account_listpartkeys"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_marknonparticipating()
{
    last_command="goal_account_marknonparticipating"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--fee=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--txfile=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--txfile=")
    flags+=("--validrounds=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_multisig_delete()
{
    last_command="goal_account_multisig_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_multisig_info()
{
    last_command="goal_account_multisig_info"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_multisig_new()
{
    last_command="goal_account_multisig_new"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--threshold=")
    two_word_flags+=("-T")
    local_nonpersistent_flags+=("--threshold=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--threshold=")
    must_have_one_flag+=("-T")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_multisig()
{
    last_command="goal_account_multisig"

    command_aliases=()

    commands=()
    commands+=("delete")
    commands+=("info")
    commands+=("new")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_new()
{
    last_command="goal_account_new"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--default")
    flags+=("-f")
    local_nonpersistent_flags+=("--default")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_partkeyinfo()
{
    last_command="goal_account_partkeyinfo"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_rename()
{
    last_command="goal_account_rename"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_renewallpartkeys()
{
    last_command="goal_account_renewallpartkeys"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--fee=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--keyDilution=")
    local_nonpersistent_flags+=("--keyDilution=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--roundLastValid=")
    local_nonpersistent_flags+=("--roundLastValid=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--roundLastValid=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_renewpartkey()
{
    last_command="goal_account_renewpartkey"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--fee=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--keyDilution=")
    local_nonpersistent_flags+=("--keyDilution=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--roundLastValid=")
    local_nonpersistent_flags+=("--roundLastValid=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_flag+=("--roundLastValid=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account_rewards()
{
    last_command="goal_account_rewards"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_account()
{
    last_command="goal_account"

    command_aliases=()

    commands=()
    commands+=("addpartkey")
    commands+=("balance")
    commands+=("changeonlinestatus")
    commands+=("delete")
    commands+=("dump")
    commands+=("export")
    commands+=("import")
    commands+=("importrootkey")
    commands+=("info")
    commands+=("installpartkey")
    commands+=("list")
    commands+=("listpartkeys")
    commands+=("marknonparticipating")
    commands+=("multisig")
    commands+=("new")
    commands+=("partkeyinfo")
    commands+=("rename")
    commands+=("renewallpartkeys")
    commands+=("renewpartkey")
    commands+=("rewards")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--default=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--default=")
    flags+=("--wallet=")
    two_word_flags+=("-w")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_call()
{
    last_command="goal_app_call"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_clear()
{
    last_command="goal_app_clear"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_closeout()
{
    last_command="goal_app_closeout"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_create()
{
    last_command="goal_app_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--global-byteslices=")
    local_nonpersistent_flags+=("--global-byteslices=")
    flags+=("--global-ints=")
    local_nonpersistent_flags+=("--global-ints=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--local-byteslices=")
    local_nonpersistent_flags+=("--local-byteslices=")
    flags+=("--local-ints=")
    local_nonpersistent_flags+=("--local-ints=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--on-completion=")
    local_nonpersistent_flags+=("--on-completion=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--creator=")
    must_have_one_flag+=("--global-byteslices=")
    must_have_one_flag+=("--global-ints=")
    must_have_one_flag+=("--local-byteslices=")
    must_have_one_flag+=("--local-ints=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_delete()
{
    last_command="goal_app_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_info()
{
    last_command="goal_app_info"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_interact_execute()
{
    last_command="goal_app_interact_execute"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--header=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_interact_query()
{
    last_command="goal_app_interact_query"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--header=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_interact()
{
    last_command="goal_app_interact"

    command_aliases=()

    commands=()
    commands+=("execute")
    commands+=("query")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--header=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_optin()
{
    last_command="goal_app_optin"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_read()
{
    last_command="goal_app_read"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--global")
    local_nonpersistent_flags+=("--global")
    flags+=("--guess-format")
    local_nonpersistent_flags+=("--guess-format")
    flags+=("--local")
    local_nonpersistent_flags+=("--local")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app_update()
{
    last_command="goal_app_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-id=")
    local_nonpersistent_flags+=("--app-id=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--app-id=")
    must_have_one_flag+=("--from=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_app()
{
    last_command="goal_app"

    command_aliases=()

    commands=()
    commands+=("call")
    commands+=("clear")
    commands+=("closeout")
    commands+=("create")
    commands+=("delete")
    commands+=("info")
    commands+=("interact")
    commands+=("optin")
    commands+=("read")
    commands+=("update")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app-account=")
    flags+=("--app-arg=")
    flags+=("--app-input=")
    two_word_flags+=("-i")
    flags+=("--approval-prog=")
    flags+=("--approval-prog-raw=")
    flags+=("--clear-prog=")
    flags+=("--clear-prog-raw=")
    flags+=("--foreign-app=")
    flags+=("--foreign-asset=")
    flags+=("--wallet=")
    two_word_flags+=("-w")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset_config()
{
    last_command="goal_asset_config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--asset=")
    local_nonpersistent_flags+=("--asset=")
    flags+=("--assetid=")
    local_nonpersistent_flags+=("--assetid=")
    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--manager=")
    local_nonpersistent_flags+=("--manager=")
    flags+=("--new-clawback=")
    local_nonpersistent_flags+=("--new-clawback=")
    flags+=("--new-freezer=")
    local_nonpersistent_flags+=("--new-freezer=")
    flags+=("--new-manager=")
    local_nonpersistent_flags+=("--new-manager=")
    flags+=("--new-reserve=")
    local_nonpersistent_flags+=("--new-reserve=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--manager=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset_create()
{
    last_command="goal_asset_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--assetmetadatab64=")
    local_nonpersistent_flags+=("--assetmetadatab64=")
    flags+=("--asseturl=")
    local_nonpersistent_flags+=("--asseturl=")
    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--decimals=")
    local_nonpersistent_flags+=("--decimals=")
    flags+=("--defaultfrozen")
    local_nonpersistent_flags+=("--defaultfrozen")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--total=")
    local_nonpersistent_flags+=("--total=")
    flags+=("--unitname=")
    local_nonpersistent_flags+=("--unitname=")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--creator=")
    must_have_one_flag+=("--total=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset_destroy()
{
    last_command="goal_asset_destroy"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--asset=")
    local_nonpersistent_flags+=("--asset=")
    flags+=("--assetid=")
    local_nonpersistent_flags+=("--assetid=")
    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--manager=")
    local_nonpersistent_flags+=("--manager=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset_freeze()
{
    last_command="goal_asset_freeze"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--account=")
    local_nonpersistent_flags+=("--account=")
    flags+=("--asset=")
    local_nonpersistent_flags+=("--asset=")
    flags+=("--assetid=")
    local_nonpersistent_flags+=("--assetid=")
    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--freeze")
    local_nonpersistent_flags+=("--freeze")
    flags+=("--freezer=")
    local_nonpersistent_flags+=("--freezer=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--account=")
    must_have_one_flag+=("--freeze")
    must_have_one_flag+=("--freezer=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset_info()
{
    last_command="goal_asset_info"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--asset=")
    local_nonpersistent_flags+=("--asset=")
    flags+=("--assetid=")
    local_nonpersistent_flags+=("--assetid=")
    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--unitname=")
    local_nonpersistent_flags+=("--unitname=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset_send()
{
    last_command="goal_asset_send"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--amount=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--amount=")
    flags+=("--asset=")
    local_nonpersistent_flags+=("--asset=")
    flags+=("--assetid=")
    local_nonpersistent_flags+=("--assetid=")
    flags+=("--clawback=")
    local_nonpersistent_flags+=("--clawback=")
    flags+=("--close-to=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--close-to=")
    flags+=("--creator=")
    local_nonpersistent_flags+=("--creator=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--to=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--to=")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--amount=")
    must_have_one_flag+=("-a")
    must_have_one_flag+=("--to=")
    must_have_one_flag+=("-t")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_asset()
{
    last_command="goal_asset"

    command_aliases=()

    commands=()
    commands+=("config")
    commands+=("create")
    commands+=("destroy")
    commands+=("freeze")
    commands+=("info")
    commands+=("send")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--wallet=")
    two_word_flags+=("-w")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_compile()
{
    last_command="goal_clerk_compile"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--account=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--account=")
    flags+=("--disassemble")
    flags+=("-D")
    local_nonpersistent_flags+=("--disassemble")
    flags+=("--no-out")
    flags+=("-n")
    local_nonpersistent_flags+=("--no-out")
    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_dryrun()
{
    last_command="goal_clerk_dryrun"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--proto=")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--proto=")
    flags+=("--txfile=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--txfile=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--txfile=")
    must_have_one_flag+=("-t")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_dryrun-remote()
{
    last_command="goal_clerk_dryrun-remote"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dryrun-state=")
    two_word_flags+=("-D")
    local_nonpersistent_flags+=("--dryrun-state=")
    flags+=("--raw")
    flags+=("-r")
    local_nonpersistent_flags+=("--raw")
    flags+=("--verbose")
    flags+=("-v")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--dryrun-state=")
    must_have_one_flag+=("-D")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_group()
{
    last_command="goal_clerk_group"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--infile=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--infile=")
    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--infile=")
    must_have_one_flag+=("-i")
    must_have_one_flag+=("--outfile=")
    must_have_one_flag+=("-o")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_inspect()
{
    last_command="goal_clerk_inspect"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_multisig_merge()
{
    last_command="goal_clerk_multisig_merge"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--out=")
    must_have_one_flag+=("-o")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_multisig_sign()
{
    last_command="goal_clerk_multisig_sign"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--no-sig")
    flags+=("-n")
    local_nonpersistent_flags+=("--no-sig")
    flags+=("--tx=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--tx=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--tx=")
    must_have_one_flag+=("-t")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_multisig_signprogram()
{
    last_command="goal_clerk_multisig_signprogram"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--address=")
    flags+=("--lsig=")
    two_word_flags+=("-L")
    local_nonpersistent_flags+=("--lsig=")
    flags+=("--lsig-out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--lsig-out=")
    flags+=("--msig-address=")
    two_word_flags+=("-A")
    local_nonpersistent_flags+=("--msig-address=")
    flags+=("--program=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--program=")
    flags+=("--program-bytes=")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--program-bytes=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--address=")
    must_have_one_flag+=("-a")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_multisig()
{
    last_command="goal_clerk_multisig"

    command_aliases=()

    commands=()
    commands+=("merge")
    commands+=("sign")
    commands+=("signprogram")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_rawsend()
{
    last_command="goal_clerk_rawsend"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filename=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--rejects=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--rejects=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--filename=")
    must_have_one_flag+=("-f")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_send()
{
    last_command="goal_clerk_send"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--amount=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--amount=")
    flags+=("--argb64=")
    local_nonpersistent_flags+=("--argb64=")
    flags+=("--close-to=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--close-to=")
    flags+=("--dryrun-dump")
    local_nonpersistent_flags+=("--dryrun-dump")
    flags+=("--dryrun-dump-format=")
    local_nonpersistent_flags+=("--dryrun-dump-format=")
    flags+=("--fee=")
    local_nonpersistent_flags+=("--fee=")
    flags+=("--firstvalid=")
    local_nonpersistent_flags+=("--firstvalid=")
    flags+=("--from=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from=")
    flags+=("--from-program=")
    two_word_flags+=("-F")
    local_nonpersistent_flags+=("--from-program=")
    flags+=("--from-program-bytes=")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--from-program-bytes=")
    flags+=("--lastvalid=")
    local_nonpersistent_flags+=("--lastvalid=")
    flags+=("--lease=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--lease=")
    flags+=("--logic-sig=")
    two_word_flags+=("-L")
    local_nonpersistent_flags+=("--logic-sig=")
    flags+=("--msig-params=")
    local_nonpersistent_flags+=("--msig-params=")
    flags+=("--no-wait")
    flags+=("-N")
    local_nonpersistent_flags+=("--no-wait")
    flags+=("--note=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--note=")
    flags+=("--noteb64=")
    local_nonpersistent_flags+=("--noteb64=")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--rekey-to=")
    local_nonpersistent_flags+=("--rekey-to=")
    flags+=("--sign")
    flags+=("-s")
    local_nonpersistent_flags+=("--sign")
    flags+=("--to=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--to=")
    flags+=("--validrounds=")
    local_nonpersistent_flags+=("--validrounds=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--amount=")
    must_have_one_flag+=("-a")
    must_have_one_flag+=("--to=")
    must_have_one_flag+=("-t")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_sign()
{
    last_command="goal_clerk_sign"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--argb64=")
    local_nonpersistent_flags+=("--argb64=")
    flags+=("--infile=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--infile=")
    flags+=("--logic-sig=")
    two_word_flags+=("-L")
    local_nonpersistent_flags+=("--logic-sig=")
    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--program=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--program=")
    flags+=("--proto=")
    two_word_flags+=("-P")
    local_nonpersistent_flags+=("--proto=")
    flags+=("--signer=")
    two_word_flags+=("-S")
    local_nonpersistent_flags+=("--signer=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--infile=")
    must_have_one_flag+=("-i")
    must_have_one_flag+=("--outfile=")
    must_have_one_flag+=("-o")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_split()
{
    last_command="goal_clerk_split"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--infile=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--infile=")
    flags+=("--outfile=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--outfile=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_flag+=("--infile=")
    must_have_one_flag+=("-i")
    must_have_one_flag+=("--outfile=")
    must_have_one_flag+=("-o")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk_tealsign()
{
    last_command="goal_clerk_tealsign"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--account=")
    local_nonpersistent_flags+=("--account=")
    flags+=("--contract-addr=")
    local_nonpersistent_flags+=("--contract-addr=")
    flags+=("--data-b32=")
    local_nonpersistent_flags+=("--data-b32=")
    flags+=("--data-b64=")
    local_nonpersistent_flags+=("--data-b64=")
    flags+=("--data-file=")
    local_nonpersistent_flags+=("--data-file=")
    flags+=("--keyfile=")
    local_nonpersistent_flags+=("--keyfile=")
    flags+=("--lsig-txn=")
    local_nonpersistent_flags+=("--lsig-txn=")
    flags+=("--set-lsig-arg-idx=")
    local_nonpersistent_flags+=("--set-lsig-arg-idx=")
    flags+=("--sign-txid")
    local_nonpersistent_flags+=("--sign-txid")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--wallet=")
    two_word_flags+=("-w")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_clerk()
{
    last_command="goal_clerk"

    command_aliases=()

    commands=()
    commands+=("compile")
    commands+=("dryrun")
    commands+=("dryrun-remote")
    commands+=("group")
    commands+=("inspect")
    commands+=("multisig")
    commands+=("rawsend")
    commands+=("send")
    commands+=("sign")
    commands+=("split")
    commands+=("tealsign")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--wallet=")
    two_word_flags+=("-w")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_completion_bash()
{
    last_command="goal_completion_bash"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_completion_zsh()
{
    last_command="goal_completion_zsh"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_completion()
{
    last_command="goal_completion"

    command_aliases=()

    commands=()
    commands+=("bash")
    commands+=("zsh")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_kmd_start()
{
    last_command="goal_kmd_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--timeout=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_kmd_stop()
{
    last_command="goal_kmd_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_kmd()
{
    last_command="goal_kmd"

    command_aliases=()

    commands=()
    commands+=("start")
    commands+=("stop")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_ledger_block()
{
    last_command="goal_ledger_block"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--b32")
    local_nonpersistent_flags+=("--b32")
    flags+=("--out=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--out=")
    flags+=("--raw")
    flags+=("-r")
    local_nonpersistent_flags+=("--raw")
    flags+=("--strict")
    local_nonpersistent_flags+=("--strict")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_ledger_supply()
{
    last_command="goal_ledger_supply"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_ledger()
{
    last_command="goal_ledger"

    command_aliases=()

    commands=()
    commands+=("block")
    commands+=("supply")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_license()
{
    last_command="goal_license"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_logging_disable()
{
    last_command="goal_logging_disable"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_logging_enable()
{
    last_command="goal_logging_enable"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_logging_send()
{
    last_command="goal_logging_send"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--channel=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--channel=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_logging()
{
    last_command="goal_logging"

    command_aliases=()

    commands=()
    commands+=("disable")
    commands+=("enable")
    commands+=("send")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network_create()
{
    last_command="goal_network_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--network=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--network=")
    flags+=("--noclean")
    local_nonpersistent_flags+=("--noclean")
    flags+=("--noimportkeys")
    flags+=("-K")
    local_nonpersistent_flags+=("--noimportkeys")
    flags+=("--template=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--template=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--rootdir=")
    two_word_flags+=("-r")

    must_have_one_flag=()
    must_have_one_flag+=("--network=")
    must_have_one_flag+=("-n")
    must_have_one_flag+=("--template=")
    must_have_one_flag+=("-t")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network_delete()
{
    last_command="goal_network_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--rootdir=")
    two_word_flags+=("-r")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network_restart()
{
    last_command="goal_network_restart"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--rootdir=")
    two_word_flags+=("-r")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network_start()
{
    last_command="goal_network_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--node=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--node=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--rootdir=")
    two_word_flags+=("-r")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network_status()
{
    last_command="goal_network_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--rootdir=")
    two_word_flags+=("-r")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network_stop()
{
    last_command="goal_network_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--rootdir=")
    two_word_flags+=("-r")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_network()
{
    last_command="goal_network"

    command_aliases=()

    commands=()
    commands+=("create")
    commands+=("delete")
    commands+=("restart")
    commands+=("start")
    commands+=("status")
    commands+=("stop")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--rootdir=")
    two_word_flags+=("-r")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_flag+=("--rootdir=")
    must_have_one_flag+=("-r")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_catchup()
{
    last_command="goal_node_catchup"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--abort")
    flags+=("-x")
    local_nonpersistent_flags+=("--abort")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_clone()
{
    last_command="goal_node_clone"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--noledger")
    flags+=("-n")
    local_nonpersistent_flags+=("--noledger")
    flags+=("--targetdir=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--targetdir=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_create()
{
    last_command="goal_node_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api=")
    local_nonpersistent_flags+=("--api=")
    flags+=("--archival")
    flags+=("-a")
    local_nonpersistent_flags+=("--archival")
    flags+=("--destination=")
    local_nonpersistent_flags+=("--destination=")
    flags+=("--hosted")
    flags+=("-H")
    local_nonpersistent_flags+=("--hosted")
    flags+=("--indexer")
    flags+=("-i")
    local_nonpersistent_flags+=("--indexer")
    flags+=("--network=")
    local_nonpersistent_flags+=("--network=")
    flags+=("--relay=")
    local_nonpersistent_flags+=("--relay=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_flag+=("--destination=")
    must_have_one_flag+=("--network=")
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_generatetoken()
{
    last_command="goal_node_generatetoken"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_lastround()
{
    last_command="goal_node_lastround"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_pendingtxns()
{
    last_command="goal_node_pendingtxns"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--maxPendingTxn=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--maxPendingTxn=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_restart()
{
    last_command="goal_node_restart"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--hosted")
    flags+=("-H")
    local_nonpersistent_flags+=("--hosted")
    flags+=("--listen=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--listen=")
    flags+=("--peer=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--peer=")
    flags+=("--telemetry=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--telemetry=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_start()
{
    last_command="goal_node_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--hosted")
    flags+=("-H")
    local_nonpersistent_flags+=("--hosted")
    flags+=("--listen=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--listen=")
    flags+=("--peer=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--peer=")
    flags+=("--telemetry=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--telemetry=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_status()
{
    last_command="goal_node_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--watch=")
    two_word_flags+=("-w")
    local_nonpersistent_flags+=("--watch=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_stop()
{
    last_command="goal_node_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node_wait()
{
    last_command="goal_node_wait"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--waittime=")
    two_word_flags+=("-w")
    local_nonpersistent_flags+=("--waittime=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_node()
{
    last_command="goal_node"

    command_aliases=()

    commands=()
    commands+=("catchup")
    commands+=("clone")
    commands+=("create")
    commands+=("generatetoken")
    commands+=("lastround")
    commands+=("pendingtxns")
    commands+=("restart")
    commands+=("start")
    commands+=("status")
    commands+=("stop")
    commands+=("wait")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_protocols()
{
    last_command="goal_protocols"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_report()
{
    last_command="goal_report"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_version()
{
    last_command="goal_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--verbose")
    flags+=("-v")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_wallet_list()
{
    last_command="goal_wallet_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_wallet_new()
{
    last_command="goal_wallet_new"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--recover")
    flags+=("-r")
    local_nonpersistent_flags+=("--recover")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_wallet()
{
    last_command="goal_wallet"

    command_aliases=()

    commands=()
    commands+=("list")
    commands+=("new")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--default=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--default=")
    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_goal_root_command()
{
    last_command="goal"

    command_aliases=()

    commands=()
    commands+=("account")
    commands+=("app")
    commands+=("asset")
    commands+=("clerk")
    commands+=("completion")
    commands+=("kmd")
    commands+=("ledger")
    commands+=("license")
    commands+=("logging")
    commands+=("network")
    commands+=("node")
    commands+=("protocols")
    commands+=("report")
    commands+=("version")
    commands+=("wallet")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--datadir=")
    two_word_flags+=("-d")
    flags+=("--kmddir=")
    two_word_flags+=("-k")
    flags+=("--version")
    flags+=("-v")
    local_nonpersistent_flags+=("--version")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_goal()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __goal_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("goal")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __goal_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_goal goal
else
    complete -o default -o nospace -F __start_goal goal
fi

# ex: ts=4 sw=4 et filetype=sh
