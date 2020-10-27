Azure RBAC Report
=================

            

The script will enumerate and report Azure subscription RBAC definitions and assigned users.


By default, the script will not report on Roles with no users enrolled. This can be overwritten with the excludeEmptyroles parameter.


.\RBACReport.ps1 -ExcludeEmptyRoles $false


 


The report will be generated in the script execution directory. In order to run the script, the session it is execute from, must be logged in to Azure using login-azurermaccount or add-azurermaccount.


The script also supports comapring information from previous report data. This will give the ability to pickup up what has changed. Changes will be highlighted in Red


Note:Special thanks to Richard de Kock for assisting with testing and feedback.


![Image](https://github.com/azureautomation/azure-rbac-report/raw/master/rbacReport.png)


 


Steps to draw reports:
In order to use the scipt you will need to ensure you are running Powershell in Administrator mode

Step 1: Preparing the environment 
Save the script on you workstation into an easy to access folder. Create an Data Archive folder and a Report Archive Folder in this folder to store your CSV file RBAC Snapshots. Rename the script by removing the .txt. Note- you may need to show file extensions
 in windows explorer to change the .txt. The system will ask you to confirm the changing of the name, accept it. Any additional guidance can be found in the script itself.


Step 2: Opening Powershell
Open PowerShell ISE and ensure the command line is reflecting the folder the script is in.

Step 3: Executing the Script to take an RBAC Assignment Snapshot
a) To execute the script type: .\RBACReportv2.ps1 -keep

b)You will be prompted to enter your credentials. Ensure you enter the correct credentials to access the Mott MacDonald tenant at a suitable role privilege to draw the report.

c) You will then be prompted to select which subscription you want to run the RBAC report on. Select the corresponding Subscription number.

The script will run and a RBAC_Report_[Date].csv file will appear, along with a RBAC_Report_[Date].html file.


Move the RBAC_Report_[Date].csv file to your Data Archive folder, and then move your RBAC_Report_[Date].html to your Report Archive folder. Only the script should be present.

You can view the HTML file to get a full view of all current allocated RBAC roles across your current tenant.


For reporting on Multiple Subscriptions it is recommended that in both the Data and the Report Archvie folders, subsequent tenant folders are created so that the associated reports can be stored accordingly.

Step 4: Comparing RBAC Roles
a) COPY the RBAC_Report CSV file that you have previously created as a snapshot from your Data Archive folder and place it in the folder the script resides in. This CSV file represents your RBAC snapshot from a point in time, so the script will take your current
 RBAC allocations and compare them to this file to determine what changes were made since the file was created.


IMPORTANT NOTE: Ensure you COPY the file from your Archive, dont move it, as the script may overright your snapshot from before.


b) Ensure that step 2 is performed, then execute the script as follows: .\RBACReportv2.ps1 -compare -PreviousReport .\RBAC_Report_[Snapshot Date].csv

Note that the last .\RBAC_Report_[Snapshot Date].csv must be the actual name of the report you want to compare your current RBAC role assignment to. This CSV is the CSV you bring back into the working folder via step a

c) You will need to enter your credentials as you did in step 3.b.

d) Select the subscription you want to report on. Select the corresponding Subscription number.

The script will run and a RBAC_Report_[Date].csv file will appear, along with a RBAC_Report_[Date].html file.


The report file will highlight all the changes from your previous run csv file. The information provided can then be further investigated using the Azure audit logs to determine who made the changes etc.


 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
