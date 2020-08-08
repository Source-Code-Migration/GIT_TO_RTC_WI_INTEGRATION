#!/bin/bash
BASE_DIR=`pwd`
GIT_DIR="/d/work/GIT/7/shell1/DuRDM"
SVN_DIR="/d/work/GIT/7/shell1/test25"

# The SVN_AUTH variable can be used in case you need credentials to commit
#SVN_AUTH="--username guilherme.chapiewski@gmail.com --password XPTO"
SVN_AUTH="--username admin --password admin"

function svn_checkin {
	echo '... adding files'
	for file in `svn st ${SVN_DIR}/trunk | awk -F" " '{print $1 "|" $2}'`; do
		fstatus=`echo $file | cut -d"|" -f1`
		fname=`echo $file | cut -d"|" -f2`

		if [ "$fstatus" == "?" ]; then
			if [[ "$fname" == *@* ]]; then
				svn add $fname@;
			else
				svn add $fname;
			fi
		fi
		if [ "$fstatus" == "!" ]; then
			if [[ "$fname" == *@* ]]; then
				svn rm $fname@;
			else
				svn rm $fname;
			fi
		fi
		if [ "$fstatus" == "~" ]; then
			rm -rf $fname;
			svn up $fname;
		fi
	done
	echo '... finished adding files'
}

function svn_commit {
	echo "... committing -> [$author]: $msg";
	cd $SVN_DIR/trunk && svn $SVN_AUTH commit --username $author -m "[$dat]:[$author]: $msg" && svn propset -rHEAD --revprop svn:date $epoch_to_date && cd $BASE_DIR;
	echo '... committed!'
}

for commit in `cd $GIT_DIR && git rev-list --all --reverse && cd $BASE_DIR`; do 
	echo "Committing $commit...";
	author=`cd ${GIT_DIR} && git log -n 1 --pretty=format:%an ${commit} && cd ${BASE_DIR}`;
	msg=`cd ${GIT_DIR} && git log -n 1 --pretty=format:%s ${commit} && cd ${BASE_DIR}`;
	dat=`cd "${GIT_DIR}" && git log -n 1 --pretty=format:%ci ${commit} && cd "${BASE_DIR}"`; 
   epoch=$(date -d "${dat}" +"%s")
   epoch_to_date=$(date -d @$epoch +"%Y-%m-%dT00:00:00.000Z")
	echo $author
	echo $dat
	echo $epoch_to_date
	echo $msg
	# Checkout the current commit on git
	echo '... checking out commit on Git'
	cd $GIT_DIR && git checkout $commit && cd $BASE_DIR;
	
	# Delete everything from SVN and copy new files from Git
	echo '... copying files'
	#rm -rf $SVN_DIR/*;

	cp -prf $GIT_DIR/* $SVN_DIR/trunk/;
	
	# Remove Git specific files from SVN
	for ignorefile in `find ${SVN_DIR} | grep .git | grep .gitignore`;
	do
		rm -rf $ignorefile;
	done
	
	# Add new files to SVN and commit
	svn_checkin && svn_commit;
done

