#  Darren Sylvain
#  March 23, 2019
#  Starts a remote session to the domain controller and adds users to the domain based on the contents of an excel (.xlsx) file

param($FILE)

#Start up the remote session the domain controller
$RPS = New-PSSession -ComputerName DC01.dominiongh.com -Credential dominiongh\administrator

try {
    $WarningPreference = "SilentlyContinue"                     #Silences errors if modules were already imported
    Import-PSSession -Session $RPS -Module ActiveDirectory
} catch {}

$WarningPreference = "Inquire"

Enter-PSSession $RPS

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
        New-ADOrganizationalUnit -name $OU -path $PARENT -ProtectedFromAccidentalDeletion $false -Confirm
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
        Write-Host "Error creating $GROUP group in $USER_PATH" -ForegroundColor Red
        return $False 
    }
}

#Checks if a useraccount exists by checking the Name variable. Returns True or False and complains.
function CheckUserExists($SAM) {
    try {
        $RESULT = Get-ADUser -Filter "SamAccountName -like '$SAM'"
        if ($RESULT) {
            Return $True
        } else {
            Return $False
        } 
    }catch {
        Write-Host "Error searching for user $SAM" -ForegroundColor Red
        Return $False
    }
}

#Creates a user with the given parameters. Returns True on success and False on defeat.
#New-ADUser returns nothing on success so the return is not checked
#TESTED
function CreateUser($FIRSTNAME,$LASTNAME,$SAM,$PASSWORD,$OU_PATH) {
    try {
        $FIRST_TEMP = $FIRSTNAME -replace '\s',''                   #Get rid of whitespace in names to create the User Principal login name (UPN)
        $LAST_TEMP = $LASTNAME -replace '\s',''
        $UPN = "$FIRST_TEMP$LAST_TEMP"    

        #More options could be added here to the New-ADUser command if more detail is required, eg. email address.
        $DEVNULL = New-ADUser  -Name "$LASTNAME $FIRSTNAME" -UserPrincipalName $UPN -SamAccountName $SAM -GivenName "$FIRSTNAME $LASTNAME" -Surname $LASTNAME -DisplayName $SAM -Department $OU -Company "Dominion Greenhouses" -AccountPassword (ConvertTo-SecureString $PASSWORD -AsPlainText -Force) -ChangePasswordAtLogon $true -Path "$OU_PATH" -Enabled $true
        $Message = 'User Firstname:{0}, LastName:{1}, PATH:{2} created' -f $FIRSTNAME,$LASTNAME,$OU_PATH
        Write-Host $Message -ForegroundColor Green 
        return $True
    } catch {
        $Message = 'Error creating User Firstname:{0}, LastName:{1}, PATH:{2}' -f $FIRSTNAME,$LASTNAME,$OU_PATH
        Write-Host $Message -ForegroundColor Red
        Exit-PSSession
        exit
    }
}

function AddUserToGroup($SAM, $GROUPS_LIST) {
    foreach ($GROUP in $GROUPS_LIST) {
        if ( -not ([string]::IsNullOrEmpty($GROUP)) ) { 
            try {
                $DEVNULL = Add-ADGroupMember "$GROUP" -Members $SAM
            } catch {
                $Message = 'Error adding user $SAM to group $GROUP'
                Write-Host $Message -ForegroundColor Red
                return $False
            }
        }
    }
    return $True
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
    $PARENT='DC=dominiongh,DC=com'
    $USER_PATH = "CN=Users,$PARENT"    #The user group path is created in the PARENT path in Users
    $FIRSTNAME = $LINE."First Name"     #Read user first name from column labeled 'First Name'
    $LASTNAME = $LINE."Last Name"       #Read user last name from column labeled 'Last Name'
    $PASSWORD = $LINE.Password        #Read user password from column labeled 'Password'
    $Group1 = $LINE.Group1                #Read user Organizational Unit from column labeled 'OU'
    $Group2 = $LINE.Group2           #Read user Main Group from column labeled 'Group2'
    $Group3 = $LINE.Group3      #Read user Special Group from column labeled 'Group3'

    #TRIM all the strings that have been read from the CSV
    $FIRSTNAME = $FIRSTNAME.Trim()
    $LASTNAME = $LASTNAME.Trim()
    $PASSWORD = $PASSWORD.Trim()
    $Group1 = $Group1.Trim()
    $Group2 = $Group2.Trim()
    $Group3 = $Group3.Trim()
    
    $SAM = "$FIRSTNAME$LASTNAME"
    if ( $SAM.Length -gt 20) { $SAM = $SAM.Substring(0,20) }    #Truncate names to 20 chars for legacy support. Could have bumped this up because we don't need legacy support.
    $GIVENNAME = "$FIRSTNAME $LASTNAME"
    $USER_IDENTITY = "CN=$GIVENNAME,$USER_PATH"


    $GROUPS = @($Group1,$Group2,$Group3)

    foreach ($GROUP in $GROUPS) {
        if ( -not ([string]::IsNullOrWhiteSpace($GROUP) )) { 
            $GROUP_PATH = "cn=$GROUP,$USER_PATH"
            $SECGROUP_EXISTS = CheckExists "$GROUP_PATH"
            if (-not ($SECGROUP_EXISTS)) {          #If the GROUP does not exist, should it be created?                            
                $SHOULD_CREATE_GROUP = Read-Host -Prompt "Group $GROUP for $FIRSTNAME $LASTNAME does not exist. Create group $GROUP_PATH ? [y|n]"
                if ($SHOULD_CREATE_GROUP -eq "y") {
                    try { 
                        $DEVNULL = CreateGroup "$GROUP" "$USER_PATH"                #CreateGroup "Finance" "CN=Users,DC=dominiongreenhouses,DC=com"
                    } catch {
                        Write-Host "Error creating $GROUP in $USER_PATH"
                        Exit-PSSession
                        exit
                    } 
                } else {
                    Write-Host "Exiting. Cannot create users in undefined Groups"
                    Exit-PSSession
                    exit
                }
            }
        }
    }
    

    #CheckOUExists takes the full path of an OU and returns True or False
    #Eg. OU_IDENTITY="OU=HQ,DC=dominiongreenhouses,DC=com" 

    #$LOCATION_OU_PATH = "OU=$Group1,$PARENT"        #The OU_IDENTITY is the full path of the OU
    #$DEPARTMENT_OU_PATH = "OU=$Group2,$OU1_PATH"           #OU2 and OU3 are nested in OU1, eg OU=Management,OU=Operations,OU=Headquarters,DC=dominiongreenhouses,DC=com
    #$SPECIAL_OU_PATH = "OU=$Group3,$OU2_PATH"
    
    $OU_PATH = $PARENT
    #The base path LOCATION_OU_PATH is just the $PARENT (cn=dominiongh,cn=com)
    #Since the OU's are being nested, the full OU path of the previous OU, including OU=<previous_OU> is the path of the next OU
    #This foolery is necessary because New-ADOrganizationalUnit used by the CreateOU function requires a path.

    foreach($OU in $GROUPS) {           #Create nested OU's from the Groups array as well, $GROUPS isn't a great name for the array
        if ( -not ([string]::IsNullOrWhiteSpace($GROUP) )) { 
            $OU_ID = "ou=$OU,$OU_PATH"
            $OU_EXISTS = CheckExists "$OU_ID"
            if( -not ($OU_EXISTS) ) {                                                   #If the OU does not exist, prompt to see if the the OU should be created
                $SHOULD_CREATE_OU = Read-host -Prompt "Create $OU_IDENTITY? [y|n]"
                if($SHOULD_CREATE_OU -eq "y") {                                         #If 'y' create the OU, any other entry stops the script
                    try {
                        DEVNULL = CreateOU "$OU" "$OU_PATH"                                       #eg. CreateOU "HQ" "DC=dominiongreenhouses,DC=com"
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
            $OU_PATH = "OU=$OU,$OU_PATH"
        }
    }

    $USER_EXISTS = CheckUserExists "$SAM"

    if ($USER_EXISTS) {
        Write-Host "User $GIVENNAME already exists. Skipping User" -ForegroundColor Cyan
    } else {
        $USER_PATH = "$OU_PATH"
        $RESULT = CreateUser "$FIRSTNAME" "$LASTNAME" "$SAM" "$PASSWORD" "$OU_PATH"     
    }
}

Write-Host "Exiting" -ForegroundColor Green
Exit-PSSession
