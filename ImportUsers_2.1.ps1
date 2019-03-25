#  Darren Sylvain
#  March 23, 2019
#  Starts a remote session to the domain controller and adds users to the domain based on the contents of an excel (.xlsx) file

param($FILE)

#Start up the remote session the domain controller
$RPS = New-PSSession -ComputerName WIN-M135PP2325P.dominiongreenhouses.com -Credential dominiongreenho\administrator
Enter-PSSession $RPS

try {
    $WarningPreference = "SilentlyContinue"                     #Stops errors if modules were already imported
    Import-PSSession -Session $RPS -Module ActiveDirectory
} catch {}

$WarningPreference = "Inquire"


function Usage {
    Write-Host "Enter a csv file to create users from" -ForegroundColor Red
    Write-Host "`n`Usage: ImportADUsers.ps1 <full\path\to\csvfile>" -ForegroundColor Green
    Exit-PSSession
    Exit
}

#This function checks if something exists in AD. Returns True or False
#eg. check if OU exists w/ IDENTITY="OU=HQ,DC=dominiongreenhouses,DC=com"
# Check if GROUP exists / IDENTITY="CN=Finance,DC=dominiongreenhouses,DC=com"
function CheckExists ($IDENTITY) {
        if([adsi]::Exists("LDAP://$IDENTITY")) {
            return $True
        } else {
            Write-Host "$IDENTITY does not exist" -ForegroundColor Yellow
            return $False
        } 
}

#Creates an Organizational Unit within the Parent Path. Returns True on Success and False on Failure.
#New-ADOrganizationalUnit returns an empty string even when it completes successfully, so there's no point checking the return value
function CreateOU ($OU, $PARENT) {
    try {
        New-ADOrganizationalUnit -name $OU -path $PARENT -ProtectedFromAccidentalDeletion $True -Confirm
        Write-Host "Created $OU in $PARENT" -ForegroundColor Green
        return $True
    } catch {
        Write-Host "Unable to create $OU in $PARENT" -ForegroundColor Red
        Exit-PSSession
        exit
    }
}


#PARENT is hardcoded "DC=dominiongreenhouses,DC=com"
#This function attempts to create the ADGroup and returns the result of the attempt
#New-ADGroup returns nothing even when it completes successfuly so there's no point checking the return value
function CreateGroup($GROUP, $USER_PATH) {
    try {
        New-ADGroup -Name $GROUP -SamAccountName $GROUP -GroupCategory Security -GroupScope Global -DisplayName $GROUP -Path $USER_PATH -Description "Created by ImportUsers.ps1 script"
        Write-Host "$GROUP group created in $USER_PATH" -ForegroundColor Green
        return $True
    } catch {
        $RESULT = $False
        Write-Host "Error creating $GROUP group in $USER_PATH" -ForegroundColor Red
        Exit-PSSession
        exit
    }
}

#Checks if a useraccount exists by checking the Name variable. Returns True or False and complains.
function CheckUserExists($FIRST,$LAST) {
    $NAME = "$LAST $FIRST"
    try {
        $RESULT = Get-ADUser -Filter "name -like '$NAME'"
        if ($RESULT) {
            Return $True
        } else {
            Return $False
        } 
    }catch {
        Write-Host "Error searching for user $NAME" -ForegroundColor Red
        Return $False
    }
}

#Creates a user with the given parameters. Returns True on success and False on defeat.
#New-ADUser returns nothing on success so the return is not checked
#TESTED
function CreateUser($FIRSTNAME,$LASTNAME,$PASSWORD,$GROUP,$USER_PATH,$MANAGEMENT) {
    try {
        $SAM = "$FIRSTNAME$LASTNAME"
        if ( $SAM.Length -gt 20) { $SAM = $SAM.Substring(0,20) }    #Truncate names to 20 chars for legacy support. Could have bumped this up because we don't need legacy support.
        $FIRST_TEMP = $FIRSTNAME -replace '\s',''                   #Get rid of whitespace in names to create the User Principal login name (UPN)
        $LAST_TEMP = $LASTNAME -replace '\s',''
        $UPN = "$FIRST_TEMP$LAST_TEMP"    

        #More options could be added here to the New-ADUser command if more detail is required, eg. email address.
        $DEVNULL = New-ADUser  -Name "$LASTNAME $FIRSTNAME" -UserPrincipalName $UPN -SamAccountName $SAM -GivenName "$FIRSTNAME $LASTNAME" -Surname $LASTNAME -DisplayName $SAM -Department $OU -Company "Dominion Greenhouses" -AccountPassword (ConvertTo-SecureString $PASSWORD -AsPlainText -Force) -ChangePasswordAtLogon $true -Path "$USER_PATH" -Enabled $true
        $Message = 'User Firstname:{0}, LastName:{1}, PATH:{2}, GROUP:{3}, Management: {4} created' -f $FIRSTNAME,$LASTNAME,$USER_PATH,$GROUP,$MANAGEMENT
        Write-Host $Message -ForegroundColor Green 
        Add-ADGroupMember $GROUP -Members $SAM
        #If the Management flag is true add the user to the Management group
        if ( $MANAGEMENT ) {
            $DEVNULL = Add-ADGroupMember "Management" -Members $SAM
        }
        return $True
    } catch {
        $Message = 'Error creating User Firstname:{0}, LastName:{1}, PATH:{2}, GROUP:{3}, Management: {4}' -f $FIRSTNAME,$LASTNAME,$USER_PATH,$GROUP,$MANAGEMENT
        Write-Host $Message -ForegroundColor Red
        Exit-PSSession
        exit
    }
}

#Checks if the given file is readable, yells otherwise.
function CheckReadable($FILE) {
    #check if file exists, otherwise print Usage and exit
    if ( Test-Path $FILE ) {
        try {
            [System.IO.File]::OpenRead($FILE).Close()
            Return $true
        } catch {
            Write-Host "$FILE is not readable" -ForegroundColor Red
            Return $false
        }
    } else {    #Test-Path $FILE has failed
        Write-Host "File doesn't exist" -ForegroundColor Red
        Return $false
    }
}




##########################################Script start#################################################


#If no file is passed on the command line print Usage and exit
if (!$FILE) { Usage }

$READABLE = CheckReadable($FILE)
if ( -not ($READABLE) ) {
    usage
    Write-Host "Exiting" -ForegroundColor Red
}

$CSVFILE = Import-Csv $FILE
ForEach ( $LINE in $CSVFile ) {
    $FIRSTNAME = $LINE."First Name"     #Read user first name from column labeled 'First Name'
    $LASTNAME = $LINE."Last Name"       #Read user last name from column labeled 'Last Name'
    $PASSWORD = $LINE.Password        #Read user password from column labeled 'Password'
    $OU = $LINE.Group1                #Read user Organizational Unit from column labeled 'OU'
    $MAINGROUP = $LINE.Group2           #Read user Main Group from column labeled 'Group2'
    $SPECIALGROUP = $LINE.Group3      #Read user Special Group from column labeled 'Group3'

    #TRIM all the strings that have been read from the CSV
    $FIRSTNAME = $FIRSTNAME.Trim()
    $LASTNAME = $LASTNAME.Trim()
    $PASSWORD = $PASSWORD.Trim()
    $OU = $OU.Trim()
    $MAINGROUP = $MAINGROUP.Trim()
    $SPECIALGROUP = $SPECIALGROUP.Trim()

    $PARENT='DC=dominiongreenhouses,DC=com'
    $OU_IDENTITY = "OU=$OU,$PARENT"     #The OU_IDENTITY is the full path of the OU
    $USER_PATH = "CN=Users,$PARENT"    #The user group path is created in the PARENT path in Users
    $MAINGROUP_IDENTITY = "CN=$MAINGROUP,$USER_PATH"
    $SPECIALGROUP_IDENTITY = "CN=$SPECIALGROUP,$USER_PATH"
    $GIVENNAME = "$FIRSTNAME $LASTNAME"
    $USER_IDENTITY = "CN=$GIVENNAME,$USER_PATH"
    

    #CheckOUExists takes the full path of an OU and returns True or False
    #Eg. OU_IDENTITY="OU=HQ,DC=dominiongreenhouses,DC=com" 
    $OU_EXISTS = CheckExists "$OU_IDENTITY"    
    if( -not ($OU_EXISTS) ) {                                                   #If the OU does not exist, prompt to see if the the OU should be created
        $SHOULD_CREATE_OU = Read-host -Prompt "Create $OU_IDENTITY? [y|n]"
        if($SHOULD_CREATE_OU -eq "y") {                                         #If 'y' create the OU, any other entry stops the script
            try {
                CreateOU "$OU" "$PARENT"                                        #eg. CreateOU "HQ" "DC=dominiongreenhouses,DC=com"
            } catch {
                Write-Host "Error creating OU $OU in Parent $PARENT. Exiting."
                Exit-PSSession                                                      #Exit the session before exiting the script
                exit
            } 
        } else {
                Write-Host "Exiting. Cannot create users in undefined AD Organizational Units"
                Exit-PSSession                                                      #Exit the session before exiting the script
                exit
        }
    }


    #Check if the current Group exists. CheckExists takes the GROUP name and the PATH to the group in the form of $PATH='CN=USERS,DC=dominiongreenhouses,DC=com'. 
    $GROUP_EXISTS = CheckExists "$MAINGROUP_IDENTITY"                           #CheckExists "CN=Finance,CN=Users,DC=dominiongreenhouses,DC=com"

    if ( -not ($GROUP_EXISTS) ) {                                               #If the GROUP does not exist, should it be created?
        $SHOULD_CREATE_GROUP = Read-Host -Prompt "Group $MAINGROUP for $FIRSTNAME $LASTNAME does not exist. Create group $MAINGROUP_IDENTITY ? [y|n]"
        if ($SHOULD_CREATE_GROUP -eq "y") {
            try { 
                $DEVNULL = CreateGroup "$MAINGROUP" "$USER_PATH"                #CreateGroup "Finance" "CN=Users,DC=dominiongreenhouses,DC=com"
            } catch {
                Write-Host "Error creating $MAINGROUP in $USER_PATH"
                Exit-PSSession
                exit
            } 
        } else {
            Write-Host "Exiting. Cannot create users in undefined Groups"
            Exit-PSSession
            exit
        }
    }
#Check if the SPECIALGROUP column from the file has something special, like 'Summer Student' or 'Manager"
#SPECIALGROUP comes from the 'Group3' column of the file and is optional
    if ( -not ([string]::IsNullOrEmpty($SPECIALGROUP)) ) {                          
        $GROUP_EXISTS = CheckExists "$SPECIALGROUP_IDENTITY"
        if ( -not ($GROUP_EXISTS) ) {
            try {
                $SHOULD_CREATE_GROUP = Read-Host -Prompt "Special Group '$SPECIALGROUP' for $FIRSTNAME $LASTNAME does not exist. Create Special Group '$SPECIALGROUP' in $SPECIALGROUP_IDENTITY ? [y|n]"
                if ($SHOULD_CREATE_GROUP -eq "y") {
                    $GROUP_CREATED = CreateGroup "$SPECIALGROUP" "$USER_PATH"               #CreateGroup "Management" "CN=Users,DC=dominiongreenhouses,DC=com"
                } else {
                    Write-Host "Exiting. Cannot create users in undefined Groups"
                    Exit-PSSession
                    exit
                }
            } catch {
                Write-Host "Error creating group $SPECIALGROUP_IDENTITY. Exiting"
                Exit-PSSession
                exit
            }
        }
    }

    $USER_EXISTS = CheckUserExists "$FIRSTNAME" "$LASTNAME"

    if ($USER_EXISTS) {
        Write-Host "User $GIVENNAME already exists. Skipping User" -ForegroundColor Cyan
    } else {
        $USER_PATH = "OU=$OU,$PARENT"
        if ( $SPECIALGROUP -eq "Management" ) {
            #CreateUser "Agent" "Smith" "P@ssw0rd" "HQ" "CN=Users,DC=dominiongreenhouses,DC=com"
            $RESULT = CreateUser "$FIRSTNAME" "$LASTNAME" "$PASSWORD" "$MAINGROUP" "$USER_PATH" $true
        } else {
            $RESULT = CreateUser "$FIRSTNAME" "$LASTNAME" "$PASSWORD" "$MAINGROUP" "$USER_PATH" $false
        }
    }
}


Write-Host "Exiting" -ForegroundColor Green
Exit-PSSession
