#!/bin/bash
# Define the global variables
export REPO=RasQberry-Two 
export STD_VENV=RQB2
#echo $HOME
#install jq
sudo apt install jq
# Function to add a bookmark to Chromium
add_bookmark() {
  local bookmark_file="$HOME/.config/chromium/Default/Bookmarks"
  local new_bookmark='{"date_added":"16855787430000000","id":1001,"name":"IBM Quantum Circuit Composer","type":"url","url":"https://quantum.ibm.com/composer/files/new"}'
  local bookmark_url="https://quantum.ibm.com/composer/files/new"

  mkdir -p "$bookmark_file"
  
  # Check if the bookmarks file exists
  if [ -f "$bookmark_file" ]; then
    # Check if the bookmark already exists
    if jq --arg url "$bookmark_url" '.roots.bookmark_bar.children[]? | select(.url == $url)' "$bookmark_file" | grep -q "$bookmark_url"; then
      #echo "Bookmark already exists. Skipping addition."
      return
    fi
    # Backup the original bookmarks file
    cp "$bookmark_file" "$bookmark_file.bak"
    # Add the new bookmark (using jq for JSON parsing)
    jq --argjson new_bookmark "$new_bookmark" '.roots.bookmark_bar.children += [$new_bookmark]' "$bookmark_file" > "$bookmark_file.tmp"
    # Replace the original bookmarks file with the updated version
    mv "$bookmark_file.tmp" "$bookmark_file"
    #echo "Bookmark added successfully."
  else
    echo "Bookmarks file not found."
  fi
}

# Call the function to add a bookmark
add_bookmark

if [ -d "$HOME/$REPO/venv/$STD_VENV" ]; then
  # echo "Virtual Env Exists"
  FOLDER_PATH="$HOME/$REPO"
  # Get the current logged-in user
  CURRENT_USER=$(whoami)
  # Check if the folder is owned by root
  if [ $(stat -c '%U' "$FOLDER_PATH") == "root" ]; then
    # Change the ownership to the logged-in user
    sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$FOLDER_PATH" "$HOME"/.*
    # echo "Ownership of $FOLDER_PATH changed to $CURRENT_USER."
  fi

  source $HOME/$REPO/venv/$STD_VENV/bin/activate
  if ! pip show qiskit > /dev/null 2>&1; then
    deactivate
    rm -fR $HOME/$REPO
    python3 -m venv $HOME/$REPO/venv/$STD_VENV
    cp -r /usr/venv/$REPO/venv/$STD_VENV/lib/python3.11/site-packages/*  $HOME/$REPO/venv/$STD_VENV/lib/python3.11/site-packages/
    sudo cp -r  /usr/bin/rq*.* $HOME/.local/bin
    sudo cp -r  /usr/config $HOME/.local/config
    source $HOME/$REPO/venv/$STD_VENV/bin/activate
  fi
else
  echo "Virtual Environment don't Exists. Creating New One ..."
  python3 -m venv $HOME/$REPO/venv/$STD_VENV
  cp -r /usr/venv/$REPO/venv/$STD_VENV/lib/python3.11/site-packages/*  $HOME/$REPO/venv/$STD_VENV/lib/python3.11/site-packages/
  sudo cp -r /usr/bin/rq*.* $HOME/.local/bin
  sudo cp -r /usr/config $HOME/.local/config
  source $HOME/$REPO/venv/$STD_VENV/bin/activate
fi

