#!/usr/bin/env bash

set -o errexit -o nounset

# When running this script on TRAVIS, first run the "setup-git-env.sh" script to set the git username accordingly

setUserInfo () {
  git config --global user.name "patternfly-build"
  git config --global user.email "patternfly-build@redhat.com"
  git config --global push.default simple
}

getDeployKey () {
  # Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
  ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
  ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
  ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
  ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
  openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
  chmod 600 deploy_key
  eval `ssh-agent -s`
  ssh-add deploy_key
}

checkRepoSlug () {
  REPO_SLUG="${1:-patternfly/patternfly}"
  REPO_BRANCH="${2:-master}"
  echo "$TRAVIS_REPO_SLUG $REPO_SLUG $REPO_BRANCH"
  if [ "${TRAVIS_REPO_SLUG}" = "${REPO_SLUG}" ]; then
    echo "This action is running against ${REPO_SLUG}."
    if [ -z "${TRAVIS_TAG}" -a "${TRAVIS_BRANCH}" != "${REPO_BRANCH}" ]; then
      echo "This commit was made against ${TRAVIS_BRANCH} and not the ${REPO_BRANCH} branch. Aborting."
      exit 1
    fi
  else
    echo "This action is not running against ${REPO_SLUG}. Aborting."
    exit 1
  fi
}

cleanSite () {
  if [ -d "patternfly.github.io" ]; then
    rm -rf patternfly.github.io
  fi
}

cloneSite () {
  git clone git@github.com:patternfly/patternfly.github.io.git
}

copySite () {
  rsync -av --delete --exclude .git source/_site/ patternfly.github.io
  find patternfly.github.io/components -type f -not -regex ".*/.*\.\(html\|js\|css\|less|otf|eot|svg|ttf|woff|woff2\)" -print0 | xargs -0 rm
}

deploySite () {
  git -C patternfly.github.io add . -A
  if [ -z "$(git -C patternfly.github.io status --porcelain)" ]; then
    echo "Site directory clean, no changes to commit."
  else
    echo "Changes in site directory clean, committing changes."
    # Check that we are committing in the patternfly.github.io repo
    THIS_REPO_SLUG=`git -C patternfly.github.io remote show -n origin | grep Fetch | cut -d: -f3`
    if [ ! $THIS_REPO_SLUG = "patternfly/patternfly.github.io.git" ]; then
      echo "${THIS_REPO_SLUG} is the wrong git repo. It should be patternfly/patternfly.github.io.git"
      exit 1
    fi
    # Commit generated files
    git -C patternfly.github.io commit -a -m "Added files generated by Travis build"
    git -C patternfly.github.io push origin master:master
  fi
}

main () {
  checkRepoSlug "patternfly/patternfly-org" "master"
  setUserInfo
  getDeployKey
  cleanSite
  cloneSite
  copySite
  deploySite
  cleanSite
}

main
