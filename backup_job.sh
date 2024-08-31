#!/bin/bash

# MySQL connection details
DB_HOST="localhost"
DB_USER="root"
DB_PASS="<Password>"
DB_NAME="jobmonitor"

# Job information
JOB_NAME="<JobName>"  # Name of the job
SERVER_IP="<IP>"  # IP address of the Source server
BACKUP_SOURCE="user@$SERVER_IP:~/Documents"  # Source path for backup
BACKUP_DEST="~/backups/$JOB_NAME"  # Destination path for backup
RSYNC_EXCLUDE="--exclude 'DayOldBackups'"  # Exclude 'DayOldBackups' directory from backup
RSYNC_OPTS="-arvze 'ssh'"  # rsync options (archive, verbose, compress, execute ssh with port 41244)

# Get current time for start time
start_time=$(date +"%Y-%m-%d %H:%M:%S")

# Function to log job status to MySQL
log_job_status() {
    local status="$1"
    local start_time="$2"
    local end_time="$3"
    local job_status="$4"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE job_runs
SET status = '$job_status', end_time = '$end_time'
WHERE job_id = $job_id AND start_time = '$start_time' AND log_date = CURDATE();
EOF
}

# Ping the server
ping "$SERVER_IP" -c 1 &>/dev/null
if [ $? -ne 0 ]; then
    end_time=$(date +"%Y-%m-%d %H:%M:%S")
    log_job_status "running" "$start_time" "$end_time" "failed"
    exit 2
fi

echo "$SERVER_IP server pinging." >> "$nagiosfile"

# Insert a new row into the job_runs table with status 'running'
job_id=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -Ns -e "SELECT job_id FROM jobs WHERE job_name = '$JOB_NAME';")
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO job_runs (job_id, start_time, end_time, status, log_date)
VALUES ($job_id, '$start_time', NULL, 'running', CURDATE());
EOF

# Perform rsync backup
rsync $RSYNC_OPTS $RSYNC_EXCLUDE "$BACKUP_SOURCE" "$BACKUP_DEST"
rsync_exit_code=$?

if [ $rsync_exit_code -eq 0 ] || [ $rsync_exit_code -eq 24 ]; then
    end_time=$(date +"%Y-%m-%d %H:%M:%S")
    log_job_status "success" "$start_time" "$end_time" "success"
    exit 0
else
    end_time=$(date +"%Y-%m-%d %H:%M:%S")
    log_job_status "failed" "$start_time" "$end_time" "failed"
    exit 2
fi
