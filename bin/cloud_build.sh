#!/bin/bash
# Travis CI dirs
CONTAINER_ISABELLE_UTP=/repo

# Guess name of Isabelle/UTP home directory unless already set.
ISABELLE_UTP=${ISABELLE_UTP:-$(readlink -f $(dirname $0))/..}

# Directory for scripts and binary executables.
BIN_DIR=$ISABELLE_UTP/bin
CONTRIB_DIR=$ISABELLE_UTP/contrib

# Check for Isabelle/UTP dependencies
bash "$BIN_DIR/utp_deps.sh"

ROOT=$ISABELLE_UTP

# Build all heap images of Isabelle/UTP
isabelle="docker run --user 0:0 --mount type=bind,source=$TRAVIS_BUILD_DIR,target=$CONTAINER_ISABELLE_UTP makarius/isabelle:Isabelle2017"
printf "\nBuilding Isabelle/UTP sessions... \n\n"

dirs=( "toolkit" "utp" "theories/designs" "theories/reactive" "theories/rea_designs" "theories/circus" "tutorial" )
heaps=( "UTP-Toolkit" "UTP" "UTP-Designs" "UTP-Reactive" "UTP-Reactive-Designs" "UTP-Circus" "UTP-Tutorial" )

for ((i=0;i<${#heaps[@]};++i));
do
	# Need to give write permissions to docker container to write to same directory. No obvious alternative.
	chmod +o+w "$ISABELLE_UTP/${dirs[i]}"
	$isabelle build -d $CONTAINER_ISABELLE_UTP -d $CONTAINER_ISABELLE_UTP/contrib -b "${heaps[i]}" || exit
        if [ -f "$ISABELLE_UTP/${dirs[i]}/output/document.pdf" ]; then
                echo "Installing ${heaps[i]} documentation to doc/${heaps[i]}.pdf..."
		cp "$ISABELLE_UTP/${dirs[i]}/output/document.pdf" "$ISABELLE_UTP/doc/${heaps[i]}.pdf"
        fi
	chmod +o-w "$ISABELLE_UTP/${dirs[i]}"
done
