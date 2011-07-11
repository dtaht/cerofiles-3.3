#!/bin/bash
# Setup a build environment for cerowrt
# ssh-keygen
# 2  ls
# 3  ls -l
# 4  ls .ssh
# 5  mv authorized_keys .ssh
# 6  cd .ssh
# 7  ls
# 8  ls -l
# 9  exit
# These are not created yet, but...
# RW is git@github.com:dtaht/cerofiles.git
ROREPOS="git://nbd.name/luci.git git://nbd.name/packages.git git://nbd.name/openwrt.git git://huchra.bufferbloat.net/git/cerofiles.git"
RWREPOS="git://github.com/bismark-devel/bismark-packages.git git://github.com/dtaht/ceropackages.git"

clones() {
while [ $# -gt 0 ]
do
git clone $1
shift
done
}


init() {

mkdir src
cd src
echo 'Establishing base repositories'

# clones

clones $ROREPOS
clones $RWREPOS

# Save disk, spin separately

git clone --reference openwrt git://huchra.bufferbloat.net/git/cerowrt cerowrt

echo 'Building sub-repositories'

cd cerowrt/
# Save some disk space on huchra
[ ! -h dl ] && [ -d ~bismark/dl ]  && ln -s ~bismark/dl dl
mkdir files
./scripts/env new dbg
cd env
git remote add ceromain git://huchra.bufferbloat.net/git/cerofiles
git pull ceromain master
cd ~/src/cerowrt/files # symbolic link, must go direct
#[ ! -s ../env/dirs.list ] & { 
#	echo "Agh! you don't have a dirs.list. Your checkout failed." 
#	exit -1
#	}
mkdir -p `cat ~/src/cerowrt/env/dirs.list`
cd ..
echo 'feeds.conf hates ~ syntax'
cat env/feeds.remote.conf | sed s#~#$HOME# > feeds.conf
# vi feeds.conf
echo 'updating feeds'

./scripts/feeds update 
./scripts/feeds install `cat env/packages.list`
cp .config config.orig
make defconfig
TC1=/tmp/dconfig.$$
cat .config | egrep '=y|=m' | sort -u > ${TC1}.new
cat config.orig | egrep '=y|=m' | sort -u > ${TC1}.old
cmp ${TC1}.new ${TC1}.old
[ $? -ne 0 ] && { echo 'Aagh! configs are different. Aborting...';
		diff ${TC1}.new ${TC1}.old
		exit -1
	      }

rm -f ${TC1}.new ${TC1}.old

mkdir -p ~/public_html/cerowrt
[ -h ~/public_html/cerowrt/cerowrt-wndr3700v2 ] && ln -s ~/src/cerowrt/bin/ar71xx ~/public_html/cerowrt/cerowrt-wndr3700v2

}

clean() {
cd ~/src
rm -rf luci packages openwrt ceropackages bismark-packages ceroconfig cerofiles public_html/cerowrt cerowrt
cd ~
}

case $1 in
	clean) clean;;
	init) init;;
esac
