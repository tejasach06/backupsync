#!/bin/bash

# MySQL connection details
DB_HOST="localhost"
DB_USER="jobmonitor_user"
DB_PASS="your_strong_password"
DB_NAME="jobmonitor"

# Email settings
RECIPIENT="recipient@example.com"
SENDER="sender@example.com"

# Get the start and end dates for the past week
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "-7 days" +"%Y-%m-%d")

# Query the database
LOGS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -Ns -e "
    SELECT j.job_name, jr.log_date, jr.start_time, jr.end_time, jr.status
    FROM jobs j
    LEFT JOIN job_runs jr ON j.job_id = jr.job_id AND jr.log_date BETWEEN '$START_DATE' AND '$END_DATE'
    ORDER BY j.job_name, jr.log_date, jr.start_time;
")

# Check if there are any logs
if [ -z "$LOGS" ]; then
    echo "No logs found for the past week ($START_DATE to $END_DATE)"
    exit 0
fi

# Create the HTML email body
HTML_BODY="<html>
<head>
    <style>
        table, th, td {
            border: 1px solid black;
            border-collapse: collapse;
            padding: 5px;
        }
    </style>
</head>
<body>
    <h2>Backup Job Logs ($START_DATE to $END_DATE)</h2>
    <table>
        <tr>
            <th>Job Name</th>
            <th>Log Date</th>
            <th>Start Time</th>
            <th>End Time</th>
            <th>Status</th>
        </tr>
        $(echo "$LOGS" | sed 's/^/        <tr><td>/g; s/ /</td><td>/g; s/$/&<\/td><\/tr>/g')
    </table>
</body>
</html>"

# Send the HTML email using Postfix
echo "$HTML_BODY" | sendmail -f "$SENDER" "$RECIPIENT"
