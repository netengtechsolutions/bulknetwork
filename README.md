# bulknet.py
A Python script that uses the netmiko library to send bulk backup, show or configuration commands to network devices.

SSH access to each device is required from the station that is running the script. Structures for network devices are hard-coded from Line 34-117.

# ImportUserstoAD_2.1.ps1
A Powershell script to add users to Active Directory while creating the necessary groups and OUs. Creation of Groups and OUs requires user confirmation. Creation of users does not require confirmation. This script checks if the user, group or OU exist before creating any of them and continues if they do, or offers to create them if they don't. An existing group or OU elicits no message but a message will be printed for an existing User. Existing Users will not be modified in any way.

A few variables are hardcoded, such as domain, user container/path, and credentials (line 8 and lines 163-169).

Use a CSV file with the headings used in 'NETE2980 - Employee Names.csv' where Group1 is the Organizational Unit, Group2 is a primary group and Group3 is an optional secondary group. Additional AD user information can be entered at line 97, like mail addresses etc.. For example, right now it will put all the new users in Company "Dominion Greenhouses". The format of the login name can be modified at lines 92-94. Currently 91 truncates the SamAccountName to 20 chars, and removes any spaces in first or last name and joins firstname+lastname to create the User Principal Name.
