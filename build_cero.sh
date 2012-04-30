#!/bin/bash
# Setup a build environment for cerowrt

if [ ! -e ~/.cero ]
then
echo 'Please setup a ~/.cero build configuration file'
echo 'Example configuration is the cero_config file'
exit
fi

. ~/.cero

clones() {
while [ $# -gt 0 ]
do
git clone $1
shift
done
}


init() {

mkdir -p $CERO_DIR
cd $CERO_DIR

echo 'Establishing base repositories'

# clones

clones $CERO_ROREPOS
clones $CERO_RWREPOS

# Bootstrapping cerofiles again if not already in this dir

[ ! -e cerofiles ] && { 
     git clone git://github.com/dtaht/cerofiles-3.3.git;
}

# Save disk, spin up cerowrt dir referencing openwrt

git clone --reference openwrt $CERO_MAIN cerowrt

# Now build up

git clone cerowrt $CERO_TARGET

echo 'Building sub-repositories'

cd $CERO_TARGET/
#mkdir files
yes | ./scripts/env new dbg
cd env
git remote add ceromain $CERO_DIR/cerofiles
git pull ceromain master
cd $CERO_DIR/$CERO_TARGET/env/files
[ ! -e ../dirs.list ] && { 
	echo "Agh! you don't have a dirs.list. Your checkout failed." 
	exit -1
	}
mkdir -p `cat ../dirs.list`
cd ../..
cat env/feeds.conf | sed s#/home/cero1/src#$CERO_DIR# > feeds.conf
echo 'updating feeds'
./scripts/feeds update 
./scripts/feeds install -p cero `cat env/override.list`
./scripts/feeds install `cat env/packages.list`
cp env/config-$CERO_TARGET .config
cp .config config.orig
mkdir -p ~/public_html/cerowrt
[ -h ~/public_html/cerowrt/cerowrt-$CERO_TARGET ] && {
    ln -s $CERO_DIR/$CERO_TARGET/bin/ar71xx ~/public_html/cerowrt/cerowrt-$CERO_TARGET ; }
make defconfig
TC1=/tmp/dconfig.$$
cat .config | egrep '=y|=m' | sort -u > ${TC1}.new
cat config.orig | egrep '=y|=m' | sort -u > ${TC1}.old
cmp ${TC1}.new ${TC1}.old
[ $? -ne 0 ] && { echo 'Aagh! configs are different. Aborting...';
		diff ${TC1}.new ${TC1}.old;
		echo 'It is ok if there are a few differences...';
		echo 'Notably, missing libraries is generally ok';
		echo "The build dir is $CERO_DIR/$CERO_TARGET";
		echo "and type 'make'";

		exit -1;
	        }

echo "The build dir is $CERO_DIR/$CERO_TARGET"
echo "There-in: type 'make'"
echo "You may have a few missing OS dependencies to resolve"

rm -f ${TC1}.new ${TC1}.old

}

clean() {
cd $CERO_DIR
rm -rf cerowrt-luci packages openwrt ceropackages bismark-packages cerofiles-3.3 public_html/cerowrt cerowrt-3.3 openflow-openwrt-bismark
cd ~
}

case $1 in
	clean) clean;;
	init) init;;
    *) echo "\"$0 init\" to initialize repositories "
esac
