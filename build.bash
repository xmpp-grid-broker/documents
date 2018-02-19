#!/usr/bin/env bash
set -eu

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
TARGET_DIRECTORY="$SCRIPT_PATH/out"

# TODO: make sure tectonic and asciidoctor are installed

function build_tex {
  tectonic "documents/$1/$1.tex"
  cp "documents/$1/$1.pdf" "$TARGET_DIRECTORY/documents/$1.pdf"
}

function build_adoc {
  asciidoctor -r asciidoctor-pdf -b pdf "$1.adoc"
  cp "$1.pdf" "$TARGET_DIRECTORY/$1.pdf"
}

function copy {
  cp -r "$1" "$TARGET_DIRECTORY/$1"
}

if [ -d "$TARGET_DIRECTORY" ]; then
  echo "cleaning up..."
  rm -r "$TARGET_DIRECTORY"
fi

echo "bootstrapping directories..."
mkdir "$TARGET_DIRECTORY"
mkdir "$TARGET_DIRECTORY/documents"
mkdir "$TARGET_DIRECTORY/documents/meeting-minutes/"

build_tex "project-plan"
build_tex "final-submission-document"

for f in "documents/meeting-minutes/"*; do
  build_adoc "${f%%.*}"
done	

build_adoc "documents/development-guide"

copy "documents/task-description-signed.pdf"
copy "documents/usage-rights.pdf"
copy "documents/time-accounting.pdf"
copy "documents/poster.pdf"
copy "project-management"
copy "presentations"

# TODO: Clone the source code repisitorie (when it exists)
# git clone git@github.com:xmpp-grid-broker/<REPO-NAME-HERE>.git "$TARGET_DIRECTORY/sources"

# TODO: create zip and .tar.gz
