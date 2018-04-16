#!/bin/bash

# Set package versions
SVN_VERSION=1.10.0
APR_VERSION=1.6.3
APR_UTIL_VERSION=1.6.1
SERF_VERSION=1.3.9
SCONS_LOCAL_VERSION=2.3.0

# Set install path
PREFIX=/pds/opt/subversion-$SVN_VERSION-testing

# Set file/directory names
SVN=subversion-$SVN_VERSION
APR=apr-$APR_VERSION
APR_UTIL=apr-util-$APR_UTIL_VERSION
SERF=serf-$SERF_VERSION
SCONS_LOCAL=scons-local-$SCONS_LOCAL_VERSION

# Set download links
SVN_LINK=https://archive.apache.org/dist/subversion/$SVN.tar.bz2
APR_LINK=https://archive.apache.org/dist/apr/$APR.tar.bz2
APR_UTIL_LINK=https://archive.apache.org/dist/apr/$APR_UTIL.tar.bz2
SERF_LINK=https://archive.apache.org/dist/serf/$SERF.tar.bz2
SCONS_LOCAL_LINK=http://prdownloads.sourceforge.net/scons/$SCONS_LOCAL.tar.gz

# Set auxiliary directories
BASEDIR=$(pwd)/temp-install-$SVN
BUILDDIR_BASE=$BASEDIR/build

# Set log file
LOG=$BASEDIR/install.log

# Set download command
DOWNLOAD="wget -nc"

# Auxiliary exit command in case of errors
die() {
  echo "error: $1" >&2
  exit
}

# Install APR
INSTALLED_APR=0
install_apr() {
BUILDDIR=$BUILDDIR_BASE.$APR_UTIL
echo "Installing $APR..."
cd $BASEDIR
echo " * downloading..."
test -f $APR.tar.bz2 || $DOWNLOAD $APR_LINK >>$LOG 2>&1 || die "downloading $APR failed"
echo " * unpacking..."
test -d $APR || tar xf $APR.tar.bz2 >>$LOG 2>&1 || die "unpacking $APR failed"
test -d $BUILDDIR && rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $BUILDDIR
echo " * configuring..."
$BASEDIR/$APR/configure --prefix=$PREFIX >>$LOG 2>&1 || die "configuring $APR failed"
echo " * building..."
make -j 10 >>$LOG 2>&1 || die "building $APR failed"
echo " * installing..."
make install >>$LOG 2>&1 || die "installing $APR failed"
echo "done."
echo
INSTALLED_APR=1
}

# Install APR-UTIL
INSTALLED_APR_UTIL=0
install_apr_util() {
BUILDDIR=$BUILDDIR_BASE.$APR_UTIL
cd $BASEDIR
echo " * downloading..."
test -f $APR_UTIL.tar.bz2 || $DOWNLOAD $APR_UTIL_LINK >>$LOG 2>&1 || die "downloading $APR_UTIL failed"
echo " * unpacking..."
test -d $APR_UTIL || tar xf $APR_UTIL.tar.bz2 >>$LOG 2>&1 || die "unpacking $APR_UTIL failed"
test -d $BUILDDIR && rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $BUILDDIR
echo " * configuring..."
LDFLAGS="-Wl,-rpath,$PREFIX/lib -Wl,-rpath,$PREFIX/lib64" \
  $BASEDIR/$APR_UTIL/configure \
  --prefix=$PREFIX --with-apr=$PREFIX >>$LOG 2>&1 || die "configuring $APR_UTIL failed"
echo " * building..."
make -j 10 >>$LOG 2>&1 || die "building $APR_UTIL failed"0
echo " * installing..."
make install >>$LOG 2>&1 || die "installing $APR_UTIL failed"l
echo "done."
echo
INSTALLED_APR_UTIL=1
}

# Install SERF
INSTALLED_SERF=0
install_serf() {
cd $BASEDIR
echo " * downloading..."
test -f $SERF.tar.bz2 || $DOWNLOAD $SERF_LINK >>$LOG 2>&1 || die "configuring $SERF failed"
echo " * unpacking..."
test -d $SERF && rm -rf $SERF
tar xf $SERF.tar.bz2 >>$LOG 2>&1 || die "unpacking $SERF failed"
cd $SERF
echo " * setting up $SCONS..."
$DOWNLOAD $SCONS_LOCAL_LINK >>$LOG 2>&1 || die "setting up $SCONS failed"
tar xf $SCONS_LOCAL.tar.gz >>$LOG 2>&1 || die "setting up $SCONS failed"
ln -s scons.py scons
echo " * configuring..."
./scons \
  LINKFLAGS="-Wl,-rpath,$PREFIX/lib -Wl,-rpath,$PREFIX/lib64" \
  APR=$PREFIX APU=$PREFIX PREFIX=$PREFIX >>$LOG 2>&1 || die "configuring $SERF failed"
echo " * building & installing..."
./scons install >>$LOG 2>&1 || die "building & installing $SERF failed"
echo "done."
echo
INSTALLED_SERF=1
}

# Install SVN
INSTALLED_SVN=0
install_svn() {
BUILDDIR=$BUILDDIR_BASE.$SVN
cd $BASEDIR
echo " * downloading..."
test -f $SVN.tar.bz2 || $DOWNLOAD $SVN_LINK >>$LOG 2>&1 || die "downloading $SVN failed"
echo " * unpacking..."
test -d $SVN || tar xf $SVN.tar.bz2 >>$LOG 2>&1 || die "unpacking $SVN failed"
test -d $BUILDDIR || rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $BUILDDIR
echo " * configuring..."
LDFLAGS="-Wl,-rpath,$PREFIX/lib -Wl,-rpath,$PREFIX/lib64" \
  $BASEDIR/$SVN/configure --prefix=$PREFIX --with-lz4=internal --with-utf8proc=internal \
  --with-apr=$PREFIX \
  --with-apr-util=$PREFIX \
  --with-serf=$PREFIX >>$LOG 2>&1 || die "configuring $SVN failed"
echo " * building..."
make -j 10 >>$LOG 2>&1 || die "building $SVN failed"
echo " * installing..."
make install >>$LOG 2>&1 || die "installing $SVN failed"
echo "done."
echo
INSTALLED_SVN=1
}

# Print usage information
usage() {
  echo "$(basename $0) [PACKAGE [PACKAGE...]]"
  echo
  echo "PACKAGE may be one of 'apr', 'apr-util', 'serf', 'svn'."
  echo "If omitted, all packages are installed."
  exit 0
}

# Show help
for i in "$@"; do
  if [ "$i" = "-h" ] || [ "$i" = "--help" ]; then
    usage
  fi
done

# Info on install prefix
echo "Subversion $SVN_VERSION and its dependencies will be installed to '$PREFIX'."
echo

# Create temporary directory
echo "Creating temporary directory '$BASEDIR'..."
test -d $BASEDIR || mkdir $BASEDIR
>$LOG
echo

# Check arguments
if [ $# -gt 0 ]; then
  # If one or more packages are requested, only install those
  for package in "$@"; do
    case $package in
      apr) install_apr;;
      apr-util) install_apr_util;;
      serf) install_serf;;
      svn) install_svn;;
      *) usage;;
    esac
  done
else
  # Otherwise install all packages
  install_apr
  install_apr_util
  install_serf
  install_svn
fi

# Delete temporary install directory
echo "Removing temporary directory '$BASEDIR'..."
rm -rf $BASEDIR
echo "done."
echo

# Install overview
echo "The following packages have been installed to $PREFIX:"
[ $INSTALLED_APR -eq 1 ] && echo " * $APR"
[ $INSTALLED_APR_UTIL -eq 1 ] && echo " * $APR_UTIL"
[ $INSTALLED_SERF -eq 1 ] && echo " * $SERF"
[ $INSTALLED_SVN -eq 1 ] && echo " * $SVN"
