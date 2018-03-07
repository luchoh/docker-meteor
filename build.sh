#!/bin/bash
# Set default settings, pull repository, build
# app, etc., _if_ we are not given a different
# command.  If so, execute that command instead.
set -e

# Default values
: ${HOME:="/home/meteor"}
: ${APP_DIR:="${HOME}/www"}      # Location of built Meteor app
: ${SRC_DIR:="${HOME}/src"}      # Location of Meteor app source
: ${BRANCH:="master"}
: ${NODE_OPTIONS:=""}         # Options to pass to Node when executing app
: ${SETTINGS_FILE:=""}        # Location of settings.json file
: ${SETTINGS_URL:=""}         # Remote source for settings.json
: ${MONGO_URL:="mongodb://${MONGO_PORT_27017_TCP_ADDR}:${MONGO_PORT_27017_TCP_PORT}/${DB}"}
: ${PORT:="3000"}
: ${RELEASE:="latest"}

# Make sure critical directories exist
mkdir -p $APP_DIR
mkdir -p $SRC_DIR

# MIN_METEOR_RELEASE is the minimum Meteor version which can be run with this script
MIN_METEOR_RELEASE=1.6.1

function checkver {
  set +e # Allow commands inside this function to fail

  # Strip "-" suffixes
  local VER=$(echo $1 | cut -d'-' -f1)

  # Format to x.y.z
  if [ $(echo $1 | wc -c) -lt 5 ]; then
    # if version is x.y, bump it to x.y.0
    RELEASE_VER=${VER}.0
  else
    # If version is x.y.z.A, truncate it to x.y.z
    RELEASE_VER=$(echo $VER |cut -d'.' -f1-3)
  fi

  semver -r '>='$MIN_METEOR_RELEASE $RELEASE_VER >/dev/null
  if [ $? -ne 0 ]; then
    echo "Application's Meteor version ($1) is less than ${MIN_METEOR_RELEASE}; please use ulexus/meteor:legacy"

    if [ -z "${IGNORE_METEOR_VERSION}" ]; then
      exit 1
    fi
  fi

  set -e
}


# See if we have a valid meteor source
METEOR_DIR=$(find ${SRC_DIR} -type d -name .meteor -print |head -n1)
if [ -e "${METEOR_DIR}" ]; then
  echo "Meteor source found in ${METEOR_DIR}"
  cd ${METEOR_DIR}/..

  # Check Meteor version
  echo "Checking Meteor version..."
  RELEASE=$(cat .meteor/release | cut -f2 -d'@')
  checkver $RELEASE

  if [ -f package.json ]; then
    echo "Installing application-side NPM dependencies..."
    meteor npm install --production
  fi

  # Bundle the Meteor app
  echo "Building the bundle in ${APP_DIR}...(this may take a while)"
  mkdir -p ${APP_DIR}
  meteor build --directory ${APP_DIR}
  echo "Done building the bundle."

  cd ${APP_DIR}/bundle
  echo "Compressing the bundle in ${APP_DIR}/bundle..."
  exec tar zcvf ../bundle.tgz *
fi
