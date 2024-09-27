#!/bin/sh
# ******Added By Rishi as part of rasQberry-two project*******
SOURCE_FILE=/home/$SUDO_USER/"$RQB2_CONFDIR/env-config.sh"
TARGET_LINK=/home/$SUDO_USER/.local/bin/env-config.sh
# Check if the symbolic link already exists
if [ -L "$TARGET_LINK" ]; 
then 
    # If the link exist remove it
    sudo rm $TARGET_LINK
    echo "Symbolic link Removed"
else
    echo "Symbolic link doesn't exists"
fi
# ***********end changes************
# Create symbolic link 
sudo ln -sf "$SOURCE_FILE" "$TARGET_LINK"
# Load environment variables
. /home/$SUDO_USER/.local/bin/env-config.sh



# Function to update values stored in the rasqberry_environment.env file
update_environment_file () {
  #check whether string is empty
  if [ -z "$2" ]||[ -z "$1" ]; then
    # whiptail message box to show error
    if [ "$INTERACTIVE" = true ]; then
      [ "$RQ_NO_MESSAGES" = false ] && whiptail --title "Error" --msgbox "Error: No value provided. Environment variable not updated" 8 78
    fi
  else
    # update environment file
    sed -i "s/^$1=.*/$1=$2/gm" /home/$SUDO_USER/$RQB2_CONFDIR/env
    # reload environment file
    . /home/$SUDO_USER/.local/bin/env-config.sh
  fi
}

# Function to update values stored in the $ENV file
# $1 = variable name, $2 = value
do_menu_update_environment_file() {
  new_value=$(whiptail --inputbox "$1" "$WT_HEIGHT" "$WT_WIDTH" --title "Type in the new value" 3>&1 1>&2 2>&3)
  update_environment_file "$1" "$new_value"
}


# Update RasQberry and create swapfile
do_rqb_system_update() {
  sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
  /etc/init.d/dphys-swapfile stop
  /etc/init.d/dphys-swapfile start
  apt update
  apt -y full-upgrade
}

#set up for demo 
setup_quantum_demo_essential() {
    update_environment_file "INTERACTIVE" "false"
    . /home/$SUDO_USER/$REPO/venv/$STD_VENV/bin/activate
    apt update
    apt install -y python3-gi gir1.2-gtk-3.0 libcairo2-dev libgirepository1.0-dev python3-numpy python3-pil python3-pkg-resources python3-sense-emu sense-emu-tools
    pip install pygobject qiskit-ibm-runtime sense-emu qiskit_aer
    python3 /home/$SUDO_USER/.local/bin/rq_set_qiskit_ibm_token.py
}

#Running quantum-raspberry-tie demo
do_rasp_tie_install() {
    setup_quantum_demo_essential
    . /home/$SUDO_USER/$REPO/venv/$STD_VENV/bin/activate
    if [ ! -f "/home/$SUDO_USER/$REPO/demos/quantum-raspberry-tie/QuantumRaspberryTie.qk1.py" ]; then
        mkdir -p /home/$SUDO_USER/$REPO/demos/quantum-raspberry-tie
        export CLONE_DIR_DEMO1="/home/$SUDO_USER/$REPO/demos/quantum-raspberry-tie"
        git clone ${GIT_REPO_DEMO1} ${CLONE_DIR_DEMO1}
    fi
    FOLDER_PATH="/home/$SUDO_USER/$REPO/demos"
    # Get the current logged-in user
    CURRENT_USER=$(whoami)
    # Check if the folder is owned by root
    if [ $(stat -c '%U' "$FOLDER_PATH") == "root" ]; then
      # Change the ownership to the logged-in user
      sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$FOLDER_PATH"
     # echo "Ownership of $FOLDER_PATH changed to $CURRENT_USER."
    fi
    if [ ! -f "/home/$SUDO_USER/$REPO/demos/quantum-raspberry-tie/QuantumRaspberryTie.qk1.py" ]; then
        whiptail --msgbox "Quantum Raspberry Tie script not found. Please ensure it's installed in the demos directory." 20 60 1
        return 1
    fi

    sh -c "cd /home/$SUDO_USER/$REPO/demos/quantum-raspberry-tie && python3 QuantumRaspberryTie.qk1.py -b:least"

    if [ -f "/home/$SUDO_USER/$REPO/demos/quantum-raspberry-ti/svg/pixels.svg" ]; then
        whiptail --msgbox "Quantum Raspberry Tie demo completed. SVG file created at /home/$SUDO_USER/$REPO/demos/quantum-raspberry-ti/svg/pixels.svg" 20 60 1
    else
        whiptail --msgbox "Quantum Raspberry Tie demo completed, but no SVG file was created." 20 60 1
    fi
}

# Initial setup for RasQberry
# Sets PATH, LOCALE, create python venv
do_rqb_initial_config() {
  ( echo; echo '##### added for rasqberry #####';
  echo 'export PATH=/home/'$SUDO_USER'/.local/bin:/home/'$SUDO_USER'/'$REPO'/demos/bin:$PATH';
  # fix locale
  echo "LANG=en_GB.UTF-8\nLC_CTYPE=en_GB.UTF-8\nLC_MESSAGES=en_GB.UTF-8\nLC_ALL=en_GB.UTF-8" > /etc/default/locale
  ) >> /home/$SUDO_USER/.bashrc && . /home/$SUDO_USER/.bashrc
  # create venv for Qiskit
  sudo -u $SUDO_USER -H -E -- sh -c 'python3 -m venv /home/'$SUDO_USER'/'$REPO'/venv/'$STD_VENV
  if [ "$INTERACTIVE" = true ]; then
      [ "$RQ_NO_MESSAGES" = false ] && whiptail --msgbox "initial config completed" 20 60 1
  fi
}

# install any version of qiskit. $1 parameter is the version (e.g. 0.37 = 037), set $2=silent for one-time silent (no whiptail popup) install
# Attention: Only works for specific Qiskit versions with predefined scripts which should be names as "rq_install_qiskitXXX.sh"
# Install latest version of Qiskit via "rq_install_qiskit_latest.sh"
do_rqb_install_qiskit() {
  sudo -u $SUDO_USER -H -- sh -c '/home/'$SUDO_USER'/.local/bin/rq_install_Qiskit'$1'.sh'
  if [ "$INTERACTIVE" = true ] && ! [ "$2" = silent ]; then
    [ "$RQ_NO_MESSAGES" = false ] && whiptail --msgbox "Qiskit $1 installed" 20 60 1
  fi
}


do_rqb_qiskit_menu() {
  FUN=$(whiptail --title "Raspberry Pi Software Configuration Tool (raspi-config)" --menu "Install Qiskit" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
    "Qnew Qiskit"      "Install Qiskit (latest version)" \
    "Q0101 Qiskit 1.1" "Install Qiskit v1.1" \
    "Q0100 Qiskit 1.0     " "Install Qiskit v1.0" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      Q0101\ *) do_rqb_install_qiskit 0101 ;;
      Q0100\ *) do_rqb_install_qiskit 0100 ;;
      Qnew\ *) do_rqb_install_qiskit _latest ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}


do_rqb_one_click_install() {
  update_environment_file "INTERACTIVE" "false"
  
  do_rqb_system_update
  do_rqb_initial_config
  do_rqb_install_qiskit 0101
  do_vnc 0
  
  update_environment_file "INTERACTIVE" "true"
  if [ "$INTERACTIVE" = true ]; then
    [ "$RQ_NO_MESSAGES" = false ] && whiptail --msgbox "Please exit and reboot" 20 60 1
  fi
  ASK_TO_REBOOT=1
}



do_quantum_demo_menu() {
  FUN=$(whiptail --title "Raspberry Pi Quantum Demo (raspi-config)" --menu "Install Quantum Demo" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
    "QRT Demo" "quantum-raspberry-tie" \
   3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      QRT\ *) do_rasp_tie_install ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
 }

do_rasqberry_menu() {
  FUN=$(whiptail --title "Raspberry Pi Software Configuration Tool (raspi-config)" --menu "System Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "OCI One-Click Install" "Run standard RQB2 setup automatically" \
    "SU System Update " "Update the system and create swapfile" \
    "IC Initial Config" "Basic configurations (PATH, LOCALE, Python venv, etc)" \
    "IQ Qiskit Install" "Install latest version of Qiskit" \
    "QD Quantum Demos"  "Install Quantum Demos"\
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      OCI\ *) do_rqb_one_click_install ;;
      SU\ *) do_rqb_system_update ;;
      IC\ *) do_rqb_initial_config ;;
      IQ\ *) do_rqb_qiskit_menu ;;
      QD\ *) do_quantum_demo_menu;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}