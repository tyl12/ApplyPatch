#!/bin/bash

origin_hash=$(git log -1 --oneline |cut -d " " -f 1)
#echo ${origin_hash}
gerritids=$@
if [ "${gerritids}" == "" ]; then
    echo "ERROR: Invalid gerritid"
    exit
fi

index=0
for gerritid in ${gerritids} ; do
    echo "-----gerritid = ${gerritid}"
    remoteserver="$(git remote)"
    if [ "${remoteserver}" == "" ]; then
        echo "ERROR: Invalid remote git repo"
        exit
    fi
    echo "-----Remote server: ${remoteserver}"
    #refs_latest="$(git ls-remote ssh://yiliangt@ctegerrit.sh.intel.com:29418/a/imc/android/platform/hardware/vlx |grep -r "2426" | awk '{print $2}' | sed 's/\// /g' | sort -n -k5 | tail -n 1 | sed 's/ /\//g')"

    #check whether the gerritid specified is in form of 'nnnn*/nn*' or 'nnnn*'
    #use the latest version if 'nnnn*'
    #otherwise use the exactly specified version of 'nnnn*/nn*'
    specified=$(expr index ${gerritid} '/')
    if [ "${specified}" == "0" ]; then
        refs_used="$(git ls-remote "${remoteserver}" |grep -r "/${gerritid}/" | awk '{print $2}' | sed 's/\// /g' | sort -n -k5 | tail -n 1 | sed 's/ /\//g')"
        echo "-----Use latest refs: $refs_used"
    else
        #gerritid_main=$(echo $gerritid | sed 's/\// /g' | awk '{print $1}')
        #gerritid_changeset=$(echo $gerritid | sed 's/\// /g' | awk '{print $2}')
        refs_used="$(git ls-remote "${remoteserver}" |grep -r "/${gerritid}\>" | awk '{print $2}')"
        echo "-----Use specified refs: $refs_used"
    fi
    if [ "${refs_used}" == "" ]; then
        echo "ERROR: Invalid refs or latest patchset"
        exit
    fi
    echo "---------------------------------------"
    git fetch ${remoteserver} ${refs_used}
    if (( $? )) ; then
        echo "ERROR: Fail to do git fetch"
        exit
    fi
    git cherry-pick FETCH_HEAD
    if (( $? )) ; then
        echo "ERROR: Fail to do git cherry-pick"
        exit
    fi
    echo ""
    echo "---------------------------------------"
    echo -e "Apply:
        index=${index}
        gerritid=${gerritid}
        server=${remoteserver}
        refs=${refs_used}"
    git log FETCH_HEAD^..FETCH_HEAD --oneline
    echo "---------------------------------------"

    let index=$index+1
    echo "Press key to continue..."
    read ans
done

echo ""
echo "New applied patches:"
git db ${origin_hash}...HEAD
echo ""
