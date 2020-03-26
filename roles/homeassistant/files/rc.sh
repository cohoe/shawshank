#!/bin/sh
#
# Based upon work by tprelog at https://github.com/tprelog/iocage-homeassistant/blob/11.3-RELEASE/overlay/usr/local/etc/rc.d/homeassistant
#
# PROVIDE: homeassistant
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# homeassistant_user: The user account used to run the homeassistant daemon.
#   This is optional, however do not specifically set this to an
#   empty string as this will cause the daemon to run as root.
#   Default: homeassistant
# homeassistant_group: The group account used to run the homeassistant daemon.
#   This is optional, however do not specifically set this to an
#   empty string as this will cause the daemon to run with group wheel.
#   Default: homeassistant
#
# homeassistant_venv: Directory where homeassistant virtualenv is installed.
#       Default:  "/usr/local/share/homeassistant"
#       Change:   `sysrc homeassistant_venv="/srv/homeassistant"`
#       UnChange: `sysrc -x homeassistant_venv`
#
# homeassistant_config_dir: Directory where homeassistant config is located.
#       Default:  "/home/homeassistant/.homeassistant"
#       Change:   `sysrc homeassistant_config_dir="/home/hass/homeassistant"`
#       UnChange: `sysrc -x homeassistant_config_dir`

# -------------------------------------------------------
# Copy this file to '/usr/local/etc/rc.d/homeassistant'
# `chmod +x /usr/local/etc/rc.d/homeassistant`
# `sysrc homeassistant_enable=yes`
# `service homeassistant start`
# -------------------------------------------------------

. /etc/rc.subr
name=homeassistant
rcvar=${name}_enable

pidfile_child="/var/run/${name}.pid"
pidfile="/var/run/${name}_daemon.pid"
logfile="/var/log/${name}.log"

load_rc_config ${name}
: ${homeassistant_enable:="NO"}
: ${homeassistant_user:="homeassistant"}
: ${homeassistant_group:="homeassistant"}
: ${homeassistant_config_dir:="/home/homeassistant/.homeassistant"}
: ${homeassistant_venv:="/usr/local/share/homeassistant"}

command="/usr/sbin/daemon"
extra_commands="check_config restart test upgrade"

start_precmd=${name}_precmd
homeassistant_precmd() {
    rc_flags="-f -o ${logfile} -P ${pidfile} -p ${pidfile_child} ${homeassistant_venv}/bin/hass --config ${homeassistant_config_dir} ${rc_flags}"
    [ ! -e "${pidfile_child}" ] && install -g ${homeassistant_group} -o ${homeassistant_user} -- /dev/null "${pidfile_child}"
    [ ! -e "${pidfile}" ] && install -g ${homeassistant_group} -o ${homeassistant_user} -- /dev/null "${pidfile}"
    [ -e "${logfile}" ] && rm -f -- "${logfile}"
    install -g ${homeassistant_group} -o ${homeassistant_user} -- /dev/null "${logfile}"
    if [ ! -d "${homeassistant_config_dir}" ]; then
      install -d -g ${homeassistant_group} -o ${homeassistant_user} -m 775 -- "${homeassistant_config_dir}"
    fi
}

stop_postcmd=${name}_postcmd
homeassistant_postcmd() {
    rm -f -- "${pidfile}"
    rm -f -- "${pidfile_child}"
}

upgrade_cmd="${name}_upgrade"
homeassistant_upgrade() {
    service ${name} stop
    su ${homeassistant_user} -c '
      source ${@}/bin/activate || exit 1
      pip3 install --upgrade homeassistant
      deactivate
    ' _ ${homeassistant_venv} || exit 1
    [ $? == 0 ] && homeassistant_check_config && service ${name} start
}

check_config_cmd="${name}_check_config"
homeassistant_check_config() {
    [ ! -e "${homeassistant_config_dir}/configuration.yaml" ] && return 0
    echo "Performing check on Home Assistant configuration:"
    #eval "${homeassistant_venv}/bin/hass --config ${homeassistant_config_dir} --script check_config"
    su ${homeassistant_user} -c '
      source ${1}/bin/activate || exit 2
      hass --config ${2} --script check_config || exit 3
      deactivate
    ' _ ${homeassistant_venv} ${homeassistant_config_dir}
}

restart_cmd="${name}_restart"
homeassistant_restart() {
    homeassistant_check_config || exit 1
    echo "Restarting Home Assistant"
    service ${name} stop
    service ${name} start
}

test_cmd="${name}_test"
homeassistant_test() {
    echo -e "\nTesting virtualenv...\n"
    [ ! -d "${homeassistant_venv}" ] && echo -e " NO DIRECTORY: ${homeassistant_venv}\n" && exit
    [ ! -f "${homeassistant_venv}/bin/activate" ] && echo -e " NO FILE: ${homeassistant_venv}/bin/activate\n" && exit

    ## switch users / activate virtualenv / get version
    su "${homeassistant_user}" -c '
      source ${1}/bin/activate || exit 2
      echo " $(python --version)" || exit 3
      echo " Home Assistant $(pip3 show homeassistant | grep Version | cut -d" " -f2)" || exit 4
      deactivate
    ' _ ${homeassistant_venv}

    [ $? != 0 ] && echo "exit $?"
}

load_rc_config ${name}
run_rc_command "$1"
