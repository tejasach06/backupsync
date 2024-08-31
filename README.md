# BackupSync

This script facilitates the backup from the source server to a local server while also logging the status of the backup job in a MySQL database.

## Usage Guide

1. Begin by installing the MySQL client on your local machine.
2. Establish a MySQL database and create a table following the provided schema in the SQL file found in this repository.
3. Create a MySQL user and grant all necessary privileges on the database to ensure seamless operation.
4. Adjust the environment variables within the script to match your MySQL setup requirements.
5. Utilize cron to schedule the backups at desired intervals.

## Necessary Environment Variables

Before executing the script, ensure the following environment variables are properly configured:

* `DB_HOST`: Hostname of the MySQL server housing the database.
* `DB_USER`: Username of the MySQL user with database access.
* `DB_PASS`: Password associated with the MySQL user.
* `DB_NAME`: Name of the MySQL database where backup status is to be logged.
* `JOB_NAME`: Name of the specific job undergoing backup, utilized in log messages.
* `SERVER_IP`: IP address of the source server from which data is backed up.
* `BACKUP_SOURCE`: Absolute path of the source directory for backup.
* `BACKUP_DEST`: Absolute path of the destination directory for backup.
* `RSYNC_EXCLUDE`: Name of the directory to be excluded from backup.

## Database Setup Commands

Below are the necessary commands to create the required database and tables for the relational database approach:

1. **Create the Database**:

```sql
CREATE DATABASE IF NOT EXISTS jobmonitor;
```

2. **Define the `jobs` Table**:

```sql
USE jobmonitor;

CREATE TABLE IF NOT EXISTS jobs (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL UNIQUE,
    job_description VARCHAR(255)
);
```

This table records information pertaining to backup jobs, utilizing `job_id` as the primary key, with each `job_name` being unique.

3. **Define the `job_runs` Table**:

```sql
CREATE TABLE IF NOT EXISTS job_runs (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME DEFAULT NULL,
    status ENUM('running', 'success', 'failed') NOT NULL,
    log_date DATE NOT NULL,
    FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);
```

This table logs entries for each run of a backup job. `run_id` serves as the primary key, with `job_id` being a foreign key referencing the `job_id` column in the `jobs` table. The `status` column accepts values of "running", "success", or "failed".

4. **Insert Data into the `jobs` Table**:

```sql
INSERT INTO jobs (job_name, job_description)
VALUES ('<Job Name>', '<Description>');
```

Replace the values with appropriate job names and descriptions for your backup jobs.

By executing these commands, you establish the necessary database and tables for the relational database approach. Remember to update the MySQL connection details (`DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`) in your script with accurate values.

For future job additions, utilize the `INSERT` statement to add new rows into the `jobs` table:

```sql
INSERT INTO jobs (job_name, job_description)
VALUES ('new_job_name', 'Description for the new job');
```

With this configuration, your script effectively logs backup job runs in the `job_runs` table, permitting easy query access using SQL.

## SQL User Configuration

Below are the commands to create a new MySQL user with necessary permissions to access the `jobmonitor` database and write data to the `job_runs` table:

1. **Create a New MySQL User**:

```sql
CREATE USER 'jobmonitor_user'@'localhost' IDENTIFIED BY 'your_strong_password';
```

This command generates a new MySQL user named `jobmonitor_user` with the password `your_strong_password`. Ensure to replace `your_strong_password` with a secure password.

2. **Grant Privileges to the New User**:

```sql
GRANT INSERT, UPDATE ON jobmonitor.job_runs TO 'jobmonitor_user'@'localhost';
FLUSH PRIVILEGES;
```

These commands confer `INSERT` and `UPDATE` privileges to the `jobmonitor_user`, specifically on the `job_runs` table within the `jobmonitor` database. `FLUSH PRIVILEGES` reloads privileges post-granting.

Post-creation, `jobmonitor_user` possesses permissions for:

- Inserting new rows into the `job_runs` table
- Updating existing rows in the `job_runs` table

No other operations are permissible (e.g., `SELECT`, `DELETE`, `CREATE`, `ALTER`, etc.) on the `jobmonitor` database. This practice aligns with the principle of least privilege, enhancing security against unauthorized access or potential data breaches.

After user creation and privilege granting, update your script with the new MySQL connection details:

```bash
# MySQL connection details
DB_HOST="localhost"
DB_USER="jobmonitor_user"
DB_PASS="your_strong_password"
DB_NAME="jobmonitor"
```

Replace `your_strong_password` with the password set for `jobmonitor_user`.

## SQL Query Enhancement

To utilize the current date dynamically instead of a hardcoded date like '2024-05-02', substitute it with the `CURDATE()` function in MySQL. `CURDATE()` returns the current date in the format 'YYYY-MM-DD'.

Here's the modified query:

```sql
SELECT j.job_name, jr.start_time, jr.end_time, jr.status
FROM jobs j
LEFT JOIN job_runs jr ON j.job_id = jr.job_id AND jr.log_date = CURDATE();
```

This query retrieves job details and log entries for the present date. To acquire logs for a specific date, replace `CURDATE()` with the desired date in 'YYYY-MM-DD' format.

For example, to fetch logs for '2024-05-02', utilize:

```sql
SELECT j.job_name, jr.start_time, jr.end_time, jr.status
FROM jobs j
LEFT JOIN job_runs jr ON j.job_id = jr.job_id AND jr.log_date = '2024-05-02';
```

By employing `CURDATE()` or specifying date ranges, flexible querying of the `job_runs` table for desired log entries becomes feasible.

## Dependencies

The script necessitates installation of the following packages:

* rsync
* MySQL client

For Debian-based systems:

    sudo apt-get install rsync mysql-client

For Redhat-based systems:

    sudo yum install rsync mysql

For Arch-based systems:

    sudo pacman -S rsync mysql