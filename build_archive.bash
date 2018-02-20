#!/usr/bin/env bash
set -eux

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
TARGET_DIRECTORY="$SCRIPT_PATH/export"

function is_in_path {
  set +e
  path_to_executable=$(which "$1" 2> /dev/null)
  set -e
  if [ ! -x "$path_to_executable" ] ; then
    echo "$1 is not in PATH"
    exit 1
  fi
}

function build_tex {
  tectonic="docker run -ti --rm --user $(id -u) --env=HOME=/tectonic --volume $(pwd):/tectonic:z fabianhauser/tectonic:0.1.6-2"
  $tectonic "documents/$1/$1.tex"
  cp "documents/$1/$1.pdf" "$TARGET_DIRECTORY/documents/$1.pdf"
}

function build_adoc {
  asciidoctor_pdf="docker run -ti --rm --user $(id -u) --volume $(pwd):/documents:z asciidoctor/docker-asciidoctor asciidoctor-pdf"
  $asciidoctor_pdf "$1.adoc"
  cp "$1.pdf" "$TARGET_DIRECTORY/$1.pdf"
}

function copy {
  cp -r "$1" "$TARGET_DIRECTORY/$1"
}

is_in_path zip

if [ -d "$TARGET_DIRECTORY" ]; then
  echo "cleaning up..."
  rm -r "$TARGET_DIRECTORY"
fi

echo "bootstrapping directories..."
mkdir "$TARGET_DIRECTORY"
mkdir "$TARGET_DIRECTORY/documents"
mkdir "$TARGET_DIRECTORY/documents/meeting-minutes/"

echo "Building PDFs..."
build_tex "project-plan"
build_tex "final-submission-document"

for f in documents/meeting-minutes/*.adoc; do
  build_adoc "${f%%.*}"
done	

build_adoc "documents/development-guide"

echo "Copy existing pdfs..."
copy "documents/task-description-signed.pdf"
copy "documents/usage-rights.pdf"
copy "documents/time-accounting.pdf"
copy "documents/poster.pdf"
copy "project-management"
copy "presentations"


# TODO: Clone the source code repos (when it exists)
# git clone git@github.com:xmpp-grid-broker/<REPO-NAME-HERE>.git "$TARGET_DIRECTORY/sources"

echo "creating archive..."
cd "$TARGET_DIRECTORY"
zip -r "../xmpp-grid-broker.zip" "./"
