#!/bin/sh
# WARNING: REQUIRES /bin/sh
#
set -e
set -x

os=`uname -s`

# Return truthy (which is zero) if a command does not exist
# (this is deliberately inverted because /bin/sh on Solaris does not support "if ! exists" syntax)
not_exists() {
  if command -v $1 >/dev/null 2>&1; then
    return 1
  else
    return 0
  fi
}

exists() {
  if command -v $1 >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

if [ "x$os" = "xAIX" ]; then
  # need to unset LIBPATH on AIX (like LD_LIBRARY_PATH on Solaris, Jenkins sets this (wrongly) on AIX)
  unset LIBPATH
fi

if [ -z $OMNIBUS_PROJECT_NAME ]; then
  echo "OMNIBUS_PROJECT_NAME environment variable is not set!"
  exit 1
fi

# create the build timestamp file for fingerprinting if it doesn't exist (manual build execution)
if [ ! -f build_timestamp ]; then
  date > build_timestamp
  echo "$BUILD_TAG / $BUILD_ID" > build_timestamp
fi

PATH=/opt/ruby-2.1.2/bin:/opt/ruby1.9/bin:/usr/local/bin:$PATH
export PATH

if [ "x$os" = "xAIX" ]; then
  # AIX is hateful and requires a bunch of root stuff to build BFF packages
  sudo rm -rf /.info || true
  sudo mkdir /.info || true
  sudo chown root /.info || true
  sudo rm -rf /tmp/bff || true
  # deinstall the bff if it got installed, can't build if it is installed
  sudo installp -u $OMNIBUS_PROJECT_NAME || true
  # AIX needs /opt/freeware/bin and /usr/sbin
  if [ -d "/opt/freeware/bin" ]; then
    PATH=/opt/freeware/bin:$PATH:/usr/sbin
    export PATH
  fi
fi

# clean up our target directory
sudo rm -rf "/opt/${OMNIBUS_PROJECT_NAME}" || true
sudo mkdir -p "/opt/${OMNIBUS_PROJECT_NAME}"
# and any old package cruft from prior builds
sudo rm -f pkg/* || true

if [ "$CLEAN" = "true" ]; then
  # nuke everything, including the git cache
  sudo rm -rf /var/cache/omnibus/* || true
else
  # we need to nuke these from old builds in order to reliably use
  # the git caching
  sudo rm -rf /var/cache/omnibus/pkg/* || true
  sudo rm -rf /var/cache/omnibus/src/* || true
  sudo rm -f /var/cache/omnibus/build/*/*.manifest || true
fi

# always fix up permissions
if [ "x$os" = "xAIX" ]; then
   sudo chown -R root "/opt/${OMNIBUS_PROJECT_NAME}"
   sudo chown -R root "/var/cache/omnibus"
else
  sudo chown -R jenkins-node "/opt/${OMNIBUS_PROJECT_NAME}" || sudo chown -R jenkins "/opt/${OMNIBUS_PROJECT_NAME}"
  sudo chown -R jenkins-node "/var/cache/omnibus" || sudo chown -R jenkins "/var/cache/omnibus"
fi

bundle install --without development

if [ "$RELEASE_BUILD" = "true" ]; then
  bundle exec omnibus build $OMNIBUS_BUILD_NAME -l debug --override append_timestamp:false
else
  bundle exec omnibus build $OMNIBUS_BUILD_NAME -l debug
fi

# Dump the build-generated version so the Omnitruck release script uses the
# correct version string format.
echo "`awk -v p=$OMNIBUS_PROJECT_NAME '$1 == p {print $2}' /opt/${OMNIBUS_PROJECT_NAME}/version-manifest.txt`" > pkg/BUILD_VERSION
