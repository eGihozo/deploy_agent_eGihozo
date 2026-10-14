deploy_agent_eGihozo

 Project Overview

This project uses a Bash script called `deploy_agent.sh` to deploy, run, and archive logs for the Student Attendance Tracker. The original Python application is not modified.

Video Walkthrough : https://youtu.be/aAsOwhWFPmY?si=alL_g5u5r5ZP12Ub

Table of Contents

1. Project Structure
2. Requirements
3. Installation and Usage
4. Main Features
5. Error Handling
6. Testing
7. Known Limitations
1. Project Structure

The repository contains the following files:

deploy_agent.sh
templates/
    attendance_checker.py
    assets.csv
    config.json
README.md


- `deploy_agent.sh`: Automates deployment, execution, and archiving.
- `attendance_checker.py`: The original attendance application.
- `assets.csv`: Sample student attendance data.
- `config.json`: Application configuration settings.
- `README.md`: Project documentation.

2. Requirements

The script requires:

- Linux or WSL
- Bash
- Python 3
- The zip utility

The script checks for required dependencies and template files before deployment.

 3. Installation and Usage

Make the script executable:

chmod +x deploy_agent.sh

Start the interactive menu:


./deploy_agent.sh

Run a specific feature directly:

./deploy_agent.sh --deploy
./deploy_agent.sh --run
./deploy_agent.sh --archive

The interactive menu provides options to deploy a project, run the application, archive logs, or exit.
 4. Main Features

 4.1 Deployment

The deployment feature checks the required files, validates the project name, and creates a project directory.

Each project has the following structure:


attendance_tracker_<name>/
    attendance_checker.py
    Helpers/
        assets.csv
        config.json
    reports/

During deployment, the script:

- Checks dependencies and template files.
- Requests a valid project name.
- Asks for confirmation before overwriting an existing project.
- Copies the application and configuration files.
- Allows the user to copy an existing roster or generate a new one.
- Sets the required file permissions.
- Offers the option to update attendance thresholds.
- Starts the application for verification.

4.2 Attendance Configuration

The script automatically sets `total_sessions` based on the selected roster.

- Existing template roster: 5 total sessions.
- Newly generated roster: 1 total session.

The default warning threshold is 75%, and the default failure threshold is 50%.

Thresholds must be whole numbers between 0 and 100. The failure threshold must be lower than the warning threshold.

4.3 Running the Application

The script checks that the project and Python application exist before running the tracker.

The application allows users to record attendance. Updated attendance data is stored in `assets.csv`, while logs are saved in the `reports/` directory.

4.4 Archiving Logs

The archive feature stores existing attendance and absence logs in timestamped directories.

Example:


attendance_tracker_<name>/
    archives/
        attendance/
        absent/

The script uses a shared timestamp for the logs, displays the archive locations, and skips missing logs without stopping the process.

4.5 Handling Interruptions

During deployment, Ctrl+C and Ctrl+Z trigger an attempt to archive the incomplete project.

The script:

1. Displays an interruption message.
2. Attempts to create a ZIP archive.
3. Deletes the incomplete project directory only if archiving succeeds.
4. Exits with status code 130.

If archiving fails, the project directory is preserved.

 5. Error Handling

The script checks for common problems, including:

- Missing dependencies or template files.
- Invalid project names.
- Invalid configuration values.
- Existing project directories.
- Missing logs.
- Unsupported command-line arguments.
 6. Testing

The script should be tested for:

- Correct project structure and file permissions.
- Successful roster generation and copying.
- Correct configuration values.
- Invalid input handling.
- Successful application execution.
- Log archiving and missing-log handling.
- Ctrl+C and Ctrl+Z interruption handling.



7. Known Limitations

- An invalid project name terminates the script instead of returning to the menu.
- Ordinary deployment errors do not automatically archive incomplete projects.
- Automatic interruption archiving applies specifically to Ctrl+C and Ctrl+Z.
 Conclusion

The script simplifies attendance tracker management by automating deployment, configuration, execution, and log archiving. It also includes input validation and interruption handling to improve reliability.
