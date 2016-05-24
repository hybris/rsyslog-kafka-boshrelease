#!/bin/bash

# Goal:
# Transform something like this:
#
# /path1/file1.err.log
# /path1/file1.log
# /filen.log
# /why/so/deep/afile.log
#
# into this:
#
# input(type="imfile" File="/path1/file1.err.log" Tag="path1.file1" Severity="error")
# input(type="imfile" File="/path1/file1.log" Tag="path1.file1" Severity="info")
# input(type="imfile" File="/filen.log" Tag="filen" Severity="info")
# input(type="imfile" File="/why/so/deep/afile.log" Tag="why.so.deep.afile" Severity="info")

template=$(cat <<EOF
input(
  type="imfile"
  File="::filepath::"
  Tag="::progname::"
  Severity="::severity::"
  freshStartTail="on"
)
EOF
)

rsyslog_reload="0"

log_dir=/var/vcap/sys/log
config_dir=/etc/rsyslog.d
config_file=00-catchall.conf

echo 'module(load="imfile")' > ${config_dir}/${config_file}.tmp

function generateFile(){

  for file in  $(find ${log_dir} -type f -name "*.log" | sort)
  do

    filepath=${file}
    severity="info"


    full_dir=$(dirname "${file}")
    short_dir=$(sed "s,${log_dir},,g" <<< ${full_dir})

    file_name=$(basename ${file})
    ext=($(echo ${file_name} | tr "." " "))

    # Checking severity from filename
    if [ ${#ext[@]} -gt 2 ];
      then
        tmp_severity=${ext[((${#ext[@]}-2))]}

        if [[ "${tmp_severity}" == *"err"* ]]
        then
          severity="error"
        fi
    fi;

    progname=${ext[0]}

    if [ "x${short_dir}" != "x" ];
    then
      prefix=$(sed "s,/,.,g" <<< ${short_dir})
      if [ "x${prefix}" != "x.${progname}" ];
      then
        progname=$(sed "s,^\.*,$1,g" <<< "${prefix}.${progname}")
      fi;
    fi;

    rsyslog_line=${template}
    rsyslog_line=$(sed "s,::filepath::,${filepath},g" <<< ${rsyslog_line})
    rsyslog_line=$(sed "s,::severity::,${severity},g" <<< ${rsyslog_line})
    rsyslog_line=$(sed "s,::progname::,${progname},g" <<< ${rsyslog_line})

    echo -e ${rsyslog_line} >> ${config_dir}/${config_file}.tmp

  done;
}

function compareLastConfig(){

  if [ ! -f ${config_dir}/${config_file} ];
  then
    rsyslog_reload="1"
    mv ${config_dir}/${config_file}.tmp ${config_dir}/${config_file}
  else
    # Compare previous config file with newly generated one
    diff ${config_dir}/${config_file}.tmp ${config_dir}/${config_file} &> /dev/null
    response=$?

    if [ "x${response}" != "x0" ];
    then
      mv ${config_dir}/${config_file}.tmp ${config_dir}/${config_file}
      rsyslog_reload="1"
    fi;
  fi
}


generateFile
compareLastConfig

if [ "x${rsyslog_reload}" != "x0" ];
then
  service rsyslog restart
fi;
