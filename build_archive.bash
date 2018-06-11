#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
TARGET_DIRECTORY="$SCRIPT_PATH/export"
ARCHIVE_NAME="xmpp-grid-broker.zip"

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
  _tectonic_base="docker run -ti --rm --user $(id -u) --env=HOME=/tectonic"
  _tectonic_image="fabianhauser/tectonic:0.1.6-2"
  tectonic="$_tectonic_base --volume $(pwd):/tectonic:z $_tectonic_image -c minimal"
  if [ "$#" -lt 2 ]; then
    $tectonic "$1" 2>&1 | sed -u "s/^/[tectonic] /"
  else
    # For documents with a glossary..
    $tectonic --keep-intermediates "$1" 2>&1 | sed -u "s/^/[tectonic] /"
    $_tectonic_base --entrypoint=/home/tectonic/bin/makeglossaries --volume $(pwd)/$2:/tectonic:z $_tectonic_image -q "$3" 2>&1 | sed -u "s/^/[makeglossaries] /"
    $tectonic  "$1" 2>&1 | sed -u "s/^/[tectonic] /"
  fi
}

function build_adoc_pdf {
  asciidoctor_pdf="docker run -ti --rm --user $(id -u) --volume $(pwd):/documents:z asciidoctor/docker-asciidoctor asciidoctor-pdf -a pdf-style=documents/.style/style.yml -a pdf-fontsdir=documents/.style/fonts"
  $asciidoctor_pdf "$1"
}
function build_adoc_html {
  asciidoctor="docker run -ti --rm --user $(id -u) --volume $(pwd):/documents:z asciidoctor/docker-asciidoctor asciidoctor"
  $asciidoctor "$1"
}

function copy {
  cp -r "$1" "$TARGET_DIRECTORY/$1"
}

is_in_path zip

if [ -d "$TARGET_DIRECTORY" ]; then
  echo "cleaning up target directory..."
  rm -rf "$TARGET_DIRECTORY"
fi
if [ -d "$ARCHIVE_NAME" ]; then
  echo "cleaning up archive..."
  rm "$ARCHIVE_NAME"
fi

echo "bootstrapping directories..."
mkdir "$TARGET_DIRECTORY"
mkdir "$TARGET_DIRECTORY/documents"

echo "Building PDFs..."

build_adoc_pdf "documents/meeting-minutes/meeting-minutes.adoc"
build_adoc_pdf "documents/development-guide.adoc"
build_adoc_pdf "documents/architectural-decisions/architectural-decisions.adoc"

build_tex "documents/project-plan/project-plan.tex"
build_tex "documents/final-submission-document/final-submission-document.tex" "documents/final-submission-document/" "final-submission-document"

build_adoc_html README.adoc

echo "Copy existing files..."
cp  "README.html" "$TARGET_DIRECTORY/index.html"
cp "logo.png" "$TARGET_DIRECTORY/favicon.ico"
cp "logo.svg" "$TARGET_DIRECTORY/"
copy "documents/usage-rights.pdf"
cp "poster/poster.pdf" "$TARGET_DIRECTORY/documents/"
cp -r "documents/final-submission-document/final-submission-document.pdf" "$TARGET_DIRECTORY/documents/"
copy "project-management"
copy "presentations"

echo "Freshly cloningo repos from remote..."
mkdir -p "$TARGET_DIRECTORY/sources/"
git clone https://github.com/xmpp-grid-broker/xmpp-grid-broker.git "$TARGET_DIRECTORY/sources/xmpp-grid-broker"
git clone https://github.com/xmpp-grid-broker/xmpp-grid-broker.git "$TARGET_DIRECTORY/sources/documents"

echo "creating archive..."
cd "$TARGET_DIRECTORY"
zip -r "../$ARCHIVE_NAME" "./"