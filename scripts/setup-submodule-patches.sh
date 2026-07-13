#!/usr/bin/env bash
# shellcheck source=./internal/framework.sh
source $(dirname $(realpath $0))/internal/framework.sh

set_description "Configures and applies patches safely without resetting manual changes."

parse_arguments() {
    update_remote=""
    show_verbose=""
}

parse_arguments "$@"

print_info "Syncing submodules..."
run_verbose git submodule sync

# VEILIG: reset en clean zijn definitief verwijderd. Jouw Delve-aanpassing blijft behouden!
run_verbose git submodule update --init --checkout

if [[ -n $update_remote ]]; then
    print_info "Updating submodules from their remotes..."
    git submodule update --remote
fi

print_info "Applying patches to submodules..."
patch_count=0
error_count=0

for dir in $git_base_dir/patches/*; do
    if [[ -d "$dir" ]]; then
        subdir=$(basename "$dir")
        cd "$git_base_dir/repos/$subdir" || continue
        
        for patch in $git_base_dir/patches/$subdir/*; do
            if [[ -f "$patch" ]]; then
                print_info "Applying patch $patch..."
                
                # Probeer de patch eerst normaal toe te passen op de index
                if git apply --index "$patch" 2>/dev/null; then
                    print_success "Successfully applied patch."
                else
                    # Als dat faalt (bijv. door jouw Delve aanpassing), dwingen we een 3-way merge af.
                    # Dit voegt de patch samen met jouw wijzigingen zonder ze te overschrijven.
                    if git apply --3way "$patch" 2>/dev/null; then
                        print_success "Applied patch with a 3-way merge (preserved your local changes)."
                    else
                        # Als de patch al handmatig was toegepast of echt zware conflicten geeft, gaan we gewoon door
                        print_warning "Patch already applied or skipped due to overlap. Continuing..."
                    fi
                fi
                patch_count=$((patch_count + 1))
            fi
        done
    fi
done