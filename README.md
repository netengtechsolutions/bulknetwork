# bulknet.py
A Python script that uses the netmiko library to send bulk backup, show or configuration commands to network devices. 
Currently accepts -h for basic usage and [-f <logfile>] to duplicate the output to a log file.

SSH access to each device is required from the station that is running the script. Structures for network devices are hard-coded from Line 34-117.

To make this work on a different network modify the device and string lists from line 119-135 to match the devices you want to connect to. The strings list is only for printing out the device name to stdout when it's being connected to and commands are being passed. The device lists are a list of the structs defined from 34-117.

The last required change is to the device_choice function from line 277-323. Set the devices variable to one of the device struct lists defined above, as well as the corresponding string to device_string. The if choice >= 5 at line 321 is essential because firewall configuration and show commands require a different function. So make sure lists of firewalls and switches/routers are kept in separate lists and that lists of firewalls are in choice>=5, or change the logic to something better. 

Those are the only modifications that are required. Tested to work on 
Switch Version 15.0(2)SE10a C2960-LANBASE SW Image C2960-LANBASEK9-M
Switch Version 12.2(55)SE5 C3560-IPSERVICESK9-M
Switch Version 16.3.5b CAT3K_CAA-UNIVERSALK9-M
Router Version 15.1(4)M6 C2800-ADVENTERPRISEK9-M
Router Version 15.2(4)M3 C2900-UNIVERSALK9-M

# ImportUsersToAD_v4.0.ps1
Extensive modifications after collaboration with my server admin made this a far better script than version v2_1 described below. OUs are created in a heirarchical structure, and security groups are created for every new OU. This allows OUs to be placed on departments within locations, such as separate OUs for Accounting at Headquarters and Manufacturing, while still having a security group that applies to all members of Accounting.



# ImportUserstoAD_v2_1.ps1
A Powershell script to add users to Active Directory while creating the necessary groups and OUs. Creation of Groups and OUs requires user confirmation. Creation of users does not require confirmation. This script checks if the user, group or OU exist before creating any of them and continues if they do, or offers to create them if they don't. An existing group or OU elicits no message but a message will be printed for an existing User. Existing Users will not be modified in any way.

A few variables are hardcoded, such as domain, user container/path, and credentials (line 8 and lines 163-169).

Use a CSV file with the headings used in 'NETE2980 - Employee Names.csv' where Group1 is the Organizational Unit, Group2 is a primary group and Group3 is an optional secondary group. Additional AD user information can be entered at line 97, like mail addresses etc.. For example, right now it will put all the new users in Company "Dominion Greenhouses". The format of the login name can be modified at lines 92-94. Currently 91 truncates the SamAccountName to 20 chars, and removes any spaces in first or last name and joins firstname+lastname to create the User Principal Name.

The provided file is in .xlsx format so one option is to convert it using Excel. CSV files should be checked for non-ascii characters prior to running ImportUserstoAD, one option is to use findnonascii.py.

# findnonascii.py
ImportUserstoAD_2.1.ps1 does not like non-ascii characters. This script will find lines with non-ascii characters and print them out with a line number so they can be manually changed before running ImportUserstoAD_v2_1.ps1

# QuantitativeRiskAnalysis
The Quantitative Risk Analysis WSA and NoCloud represent the simulations that we ran to check the return on investment for moving our DMZ to the Cloud. NoCloud represents a local DMZ whereas WSA represents either the addition of a Web Security Appliance or Quarterly end-user training. We assumed that either a WSA or End-User training would have a similiar decrease in probabilities for the security events that we are measuring. 

The easiest gains were moving services to the cloud that would require a DMZ, like email and the website. We also propose regular end-user training, which results in the green line. The attacker’s dilemma is finding a way in. By eliminating untrusted remote access and training users not to click things we reduced the attack surface significantly. The reduction DMZ vs the Cloud in the simulations is the result of lowering the probabilities of certain compromises by 10-15%, so if the chance of a particular compromise was 20% then we’re proposing that can be reduced from once every 5 years to once every 10 years by using the cloud instead of a DMZ. The difference from the red to green lines is a significant reduction in unprivileged initial entry based on social engineering. This modest reduction also assumes that in nearly all cases unprivileged host access does not escalate to privileged local or domain access, otherwise the cost reduction could potentially be much more. 

# Team_Trogdor_Final_Capstone_Documentation
Our completed proposal.
