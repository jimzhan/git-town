# Helper methods for working with Git.


# The file name of the configuration file.
#
# This file just contains the name of the main development branch.
# Typically this is either 'master' or 'development'.
config_filename=".main_branch_name"

# Name of the temp file to use.
temp_filename="/tmp/git_input_$$"


# Checks out the branch with the given name.
#
# Skips this operation if the requested branch
# is already checked out.
function checkout_branch {
  determine_current_branch_name
  if [ ! "$current_branch_name" = "$1" ]; then
    git checkout $1
  fi
}


# Checks out the main development branch in Git.
#
# Skips the operation if we already are on that branch.
function checkout_main_branch {
  checkout_branch $main_branch_name
}


# Checks out the current feature branch in Git.
#
# Skips the operation if we already are on that branch.
function checkout_feature_branch {
  checkout_branch $feature_branch_name
}


# Creates the configuration file with data asked from the user.
function create_config_file {
  echo "Please enter the name of the main dev branch (typically 'master' or 'development'):"
  read main_branch_name
  if [[ -z "$main_branch_name" ]]; then
    echo_error_header
    echo "  You have not provided the name for the main branch."
    echo "  This information is necessary to run this script."
    echo "  Please try again."
    exit_with_error
  fi
  echo $main_branch_name > $config_filename
  echo
  echo "I have created this file with content $main_branch_name for you."
  echo Please add this file to your .gitignore,
  echo then run this script again to continue.
  exit_with_error
}


# Creates a new feature branch with the given name.
#
# The feature branch is cut off the main development branch.
function create_feature_branch {
  echo_header "Creating the '$1' branch off the '$main_branch_name' branch"
  git checkout -b $1 $main_branch_name
}


# Deletes the given feature branch from both the local machine
# as well as from Github.
function delete_feature_branch {
  echo_header "Removing the old '$feature_branch_name' branch"
  checkout_feature_branch
  determine_tracking_branch
  if $has_tracking_branch; then
    git push
  fi
  checkout_main_branch
  git br -d $feature_branch_name
  if $has_tracking_branch; then
    git push origin :${feature_branch_name}
  fi
}


# Removes the temp file.
function delete_temp_file {
  rm $temp_filename
}


# Determines the current Git branch name.
#
# Makes the result available in the global variable $current_branch_name.
#
# Call this method, and not 'determine_feature_branch_name', if you want
# to get the current git branch.
function determine_current_branch_name {
  current_branch_name=`git branch | grep "*" | awk '{print $2}'`
}


# Determines the name of the current Git feature branch that we are
# working on.
#
# Makes the result available in the global variable $feature_branch_name.
#
# If you need to know which branch we are curently on, please call
# determine_current_branch_name and access $current_branch_name.
#
# The idea is that the user starts the script in the feature branch,
# we read the branch name using this script once in the beginning,
# and then we don't touch this variable anymore by not running this script
# ever again.
function determine_feature_branch_name {
  feature_branch_name=`git branch | grep "*" | awk '{print $2}'`
}


# Determines the name of the 'development' branch in Git.
#
# Sets the global variable $main_branch_name with the result.
#
# This value is read from a file '.main_branch_name' in the
# working directory.
function determine_main_branch_name {
  if [[ ! -f $config_filename ]]; then
    echo_error_header
    echo "  Didn't find the $config_filename file."
    echo
    create_config_file
  fi
  main_branch_name=`cat $config_filename`
}


# Determines whether there are open changes in Git.
#
# Makes the result available in the global variable $has_open_changes.
function determine_open_changes {
  if [ $((`git status --porcelain | wc -l`)) == 0 ]; then
    has_open_changes=false
  else
    has_open_changes=true
  fi
}


# Determines whether the feature branch has a remote tracking branch.
#
# Makes the result available in the global variable $has_tracking_branch.
function determine_tracking_branch {
  echo $feature_branch_name
  if [ $((`git br -vv | grep "\* $feature_branch_name\b" | grep '\[.*\]' | wc -l`)) == 0 ]; then
    has_tracking_branch=false
  else
    has_tracking_branch=true
  fi
}


function ensure_dialog_tool {
  if [ $((`which dialog | wc -l`)) == 0 ]; then
    echo_error_header
    echo "  You need the 'dialog' tool in order to run this script."
    echo
    echo "  Please install it using your package manager on Linux,"
    echo "  or with 'brew install dialog' on OS X."
    exit_with_error
  fi
}


# Exists the application with an error message if the
# current working directory contains uncommitted changes.
function ensure_no_open_changes {
  if $has_open_changes; then
    echo_header "  Error"
    echo $*
    exit_with_error
  fi
}


# Exists the application with an error message if the working directory
# is on the main development branch.
function ensure_on_feature_branch {
  determine_current_branch_name
  if [ "$current_branch_name" = "$main_branch_name" ]; then
    echo_error_header
    echo "  $1"
    exit_with_error
  fi
}


# Exits the currently running script with an error response code.
function exit_with_error {
  echo
  echo
  exit 1
}


# Merges the current feature branch into the main dev branch.
function merge_feature_branch {
  echo_header "Merging the '$feature_branch_name' branch into '$main_branch_name'"
  checkout_main_branch
  git merge --squash $feature_branch_name && git commit -a
}


# Pushes the feature branch to Github.
function push_feature_branch {
  echo_header "Pushing '$feature_branch_name' to Github"
  checkout_feature_branch
  determine_tracking_branch
  echo $has_tracking_branch
  if $has_tracking_branch; then
    git push
  else
    git push -u origin $feature_branch_name
  fi
}


# Unstashes changes that were stashed in the beginning of a script.
#
# Only does this if there were open changes when the script was started.
function restore_open_changes {
  if $has_open_changes; then
    echo_header "Restoring uncommitted changes"
    git stash pop
  fi
}


# Stashes uncommitted changes if they exist.
function stash_open_changes {
  if $has_open_changes; then
    echo_header "Stashing uncommitted changes"
    git add -A
    git stash
  fi
}


# Updates the current feature branch.
function update_feature_branch {
  echo_header "Updating the '$current_branch_name' branch"
  checkout_feature_branch
  git rebase $main_branch_name
}


# Updates the current development branch.
function update_main_branch {
  echo_header "Updating the '$main_branch_name' branch"
  checkout_main_branch
  git pull --rebase
}



determine_main_branch_name
determine_open_changes
determine_current_branch_name
determine_feature_branch_name