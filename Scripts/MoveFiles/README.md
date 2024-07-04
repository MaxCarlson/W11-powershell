### MoveFiles

This subfolder contains scripts for organizing and managing files by moving them based on their age. These scripts are designed to automate file management tasks such as moving older files to a specified destination.

**Key Scripts:**

- **MoveOneDayOldRecursivelyFinal.ps1**: Moves files older than one day from the source to the destination directory.
  - **Parameters**:
    - `-source`: Source directory containing the files to be moved.
    - `-destination`: Destination directory where the files will be moved.
    - `-verbose`: (Optional) Enables verbose output.
  - **Usage**:
    ```powershell
    .\MoveOneDayOldRecursivelyFinal.ps1 -source "C:\path\to\source" -destination "C:\path\to\destination" -verbose $true
    ```

- **SetupSchedule.ps1**: Sets up a scheduled task to run the `MoveOneDayOldRecursivelyFinal.ps1` script at regular intervals.
  - **Parameters**:
    - `-verbose`: (Optional) Enables verbose output.
    - `-taskName`: Name of the scheduled task.
    - `-description`: Description of the scheduled task.
  - **Usage**:
    ```powershell
    .\SetupSchedule.ps1 -verbose $true -taskName "MoveFilesDaily" -description "Daily File Move"
    ```

**Log Files:**
- **iplog.log**: Logs the history of IP addresses assigned to the WSL2 instance.
- **WSL2-Last-IP.txt**: Stores the last known WSL2 IP address for comparison.

**Contributing:**
Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure that your code follows the project's coding standards and includes appropriate tests.

**License:**
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

**Contact:**
For any questions or issues, please contact me at carlsonamax@gmail.com.