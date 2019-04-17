"""
    Title:      bulknetwork.py
    Desc:       Send bulk network commands to devices with netmiko
    Date:       March 2, 2019
    Version:    1.3
    Python Ver: 3.6.8
    Writer:	Darren Sylvain

"""

import sys, getopt
import getopt
from netmiko import ConnectHandler
from datetime import datetime
from getpass import getpass 
import random

# netmiko : multi-vendor library to simplify Paramiko SSH connections to network devices : https://github.com/ktbyers/netmiko
# datetime : used to determine and print out how long a function takes to run
# getpass : allows the script to ask for the password when it runs rather than hardcoding it here
#   request the password from user
# random is used to generate a value to tack onto the end of the save name when saved to flash, because
#   the script chokes if a file with same name already exists
password = getpass()

# create a dictionary representing each device
# supported device_types can be found on the github page
# global_delay_factor tells Netmiko to wait longer than default (default ~100seconds) for the command to complete
#   global_delay_factor=2 doubles the value of ALL delays. (delay_factor=2 would have doubled only delays after send_command
#   which would likely work as well but I'm not in a hurry)

# Device Naming convention <Location>_<(C)ore|(D)istribution|(A)ccess>_<Device><Device#>
# TODO: use sqlite for device dictionaries so this can be removed from the script
HQ_A_SW1 = {
        'device_type': 'cisco_ios',
        'ip': '10.1.150.10',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
HQ_A_SW2 = {
        'device_type': 'cisco_ios',
        'ip': '10.1.150.11',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
HQ_D_SW1 = {
        'device_type': 'cisco_ios',
        'ip': '10.1.250.250',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
HQ_D_SW2 = {
        'device_type': 'cisco_ios',
        'ip': '10.1.250.252',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
HQ_C_FW1 = {
        'device_type': 'cisco_asa',
        'ip': '10.1.200.6',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
MP_A_SW1 = {
        'device_type': 'cisco_ios',
        'ip': '10.2.150.10',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
MP_A_SW2 = {
        'device_type': 'cisco_ios',
        'ip': '10.2.150.11',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
MP_D_R1 = {
        'device_type': 'cisco_ios',
        'ip': '10.2.250.250',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
MP_D_R2 = {
        'device_type': 'cisco_ios',
        'ip': '10.2.250.252',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
MP_C_FW1 = {
        'device_type': 'cisco_asa',
        'ip': '172.31.133.60',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
WH_A_SW1 = {
        'device_type': 'cisco_ios',
        'ip': '10.3.250.254',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}
WH_C_FW1 = {
        'device_type': 'cisco_asa',
        'ip': '172.31.133.65',
        'username': 'trogdor',
        'password': password,
        'global_delay_factor': 2,
}

#Temporary bunch of lists and strings. The strings are used to print information about which device is being connected to by Netmiko
HQ_network_devices = [HQ_A_SW1, HQ_A_SW2, HQ_D_SW1, HQ_D_SW2]
HQ_network_devices_strings = ['HQ_A_SW1', 'HQ_A_SW2', 'HQ_D_SW1', 'HQ_D_SW2']
MP_access_devices = [MP_A_SW1, MP_A_SW2]
MP_access_devices_strings = ['MP_A_SW1', 'MP_A_SW2', 'MP_D_R1', 'MP_D_R2']
WH_network_devices = [WH_A_SW1]
WH_network_devices_strings = ['WH_A_SW1']
all_network_devices = [HQ_A_SW1, HQ_A_SW2, HQ_D_SW1, HQ_D_SW2, MP_A_SW1, MP_A_SW2, MP_D_R1, MP_D_R2, WH_A_SW1]
all_network_devices_strings = ['HQ_A_SW1', 'HQ_A_SW2', 'HQ_D_SW1', 'HQ_D_SW2', 'MP_A_SW1', 'MP_A_SW2', 'MP_D_R1', 'MP_D_R2', 'WH_A_SW1']
all_firewalls = [HQ_C_FW1, MP_C_FW1, WH_C_FW1]
all_firewalls_strings = ['HQ_C_FW1', 'MP_C_FW1', 'WH_C_FW1']
AllSwitches = [HQ_A_SW1, HQ_A_SW2, HQ_D_SW1, HQ_D_SW2, MP_A_SW1, MP_A_SW2, WH_A_SW1]
AllSwitches_strings = ['HQ_A_SW1', 'HQ_A_SW2', 'HQ_D_SW1', 'HQ_D_SW2', 'MP_A_SW1', 'MP_A_SW2', 'WH_A_SW1']
MP_firewalls = [MP_C_FW1]
MP_firewalls_strings = ['MP_C_FW1']
WH_firewalls = [WH_C_FW1]
WH_firewalls_strings = ['WH_C_FW1']

#Pretty much all functions use total_time = end_time - start_time just to time the function call
#The ssh connections are handled by ConnectHandler, devices require ssh access

def configure(devices, devices_strings, cmd):
    #Send a single configuration command to the device
    #This could be modified to accept multiple commands but cmd would have to be passed as a list
    #   of strings, and then the 'config_commands = [cmd]' command can be omitted.
    start_time = datetime.now()
    i = 0
    for each_device in devices:
        net_connect = ConnectHandler(**each_device)
        print (f'Connecting to {devices_strings[i]} and sending \'{cmd}\'')
        config_commands = [cmd]
        output = net_connect.send_config_set(config_commands)
        print(f"\n\n========Device {devices_strings[i]}-{each_device['device_type']} ========")
        i = i + 1
        print(output)
        print("++++++++ End ++++++++")
    end_time = datetime.now()
    total_time = end_time - start_time
    print(f'configure duration : {total_time}')    

def show(devices, devices_strings, cmd, logfile=False):
    start_time = datetime.now()
    i = 0
    for each_device in devices:
        net_connect = ConnectHandler(**each_device)
        print (f'Connecting to {devices_strings[i]} and sending \'{cmd}\'')
        output = net_connect.send_command(cmd)
        #print header
        print(f"\n\n========Device {devices_strings[i]}-{each_device['device_type']} ========")
        devicestring = f"\n\n========Device {devices_strings[i]}-{each_device['device_type']} ========"
        cmdstring = f"\tResults of command : {cmd}"
        i = i + 1
        print(output)
        if logfile:
            print(devicestring, '\n', cmdstring,'\n', output,file=open(logfile,'a'))
            print("++++++++ End ++++++++")
    end_time = datetime.now()
    total_time = end_time - start_time
    print(f'configure duration : {total_time}')   

def backup_firewalls_flash(firewalls, firewalls_strings):
    start_time = datetime.now()
    randvalue = random.randint(1,100000)
    i = 0
    for each_firewall in firewalls:
        net_connect = ConnectHandler(**each_firewall)
        print (f"\nConnecting to {firewalls_strings[i]} and sending backup to flash command")
        cmd = f'copy run disk0:/backup_config_{start_time.month}_{start_time.day}_{randvalue}'  
        output = net_connect.send_command(
                cmd,
                expect_string=r'Source filename'
                )
        output += net_connect.send_command('\n', expect_string=r'Destination filename')
        output += net_connect.send_command('\n', expect_string=r'#')
        print(f"\n\n========Device {firewalls_strings[i]}-{each_firewall['device_type']} ========")
        i = i + 1
        print(output)
        print("++++++++ End ++++++++")
    end_time = datetime.now()
    total_time = end_time - start_time
    print(f'backup_firewalls_flash duration : {total_time}')

def backup_network_devices_flash(network_devices, network_devices_strings):
    start_time = datetime.now()
    randvalue = random.randint(1,100000)
    i = 0
    for each_device in network_devices:
        net_connect = ConnectHandler(**each_device)
        print (f"\nConnecting to {network_devices_strings[i]} and sending backup to flash command")
        cmd = f'copy run flash:/backup_config_{start_time.month}_{start_time.day}_{randvalue}'
        output = net_connect.send_command(
                cmd,
                expect_string=r'Destination filename'
                )
        output += net_connect.send_command('\n', expect_string=r'#')
        print(f"\n\n========Device {network_devices_strings[i]}-{each_device['device_type']} ========")
        i = i + 1
        print(output)
        print("++++++++ End ++++++++")
    end_time = datetime.now()
    total_time = end_time - start_time
    print(f'backup_network_devices_flash duration : {total_time}')

def backup_firewalls_tftp(firewalls, firewalls_strings, tftp_server):
    start_time = datetime.now()
    randvalue = random.randint(1,100000)
    i = 0
    for each_firewall in firewalls:
        net_connect = ConnectHandler(**each_firewall)
        print (f"\nConnecting to {firewalls_strings[i]} and sending backup to tftp command")
        cmd = f'copy running-config tftp:'  
        dest_filename = f'{firewalls_strings[i]}_{start_time.month}_{start_time.day}_{start_time.year}_{randvalue}'
        print (f'Attempting to save config as {dest_filename}')
        output = net_connect.send_command(cmd, expect_string=r'Source filename')
        output += net_connect.send_command('', expect_string=r'Address or name of remote host')
        output += net_connect.send_command(f'{tftp_server}', expect_string=r'Destination filename')
        output += net_connect.send_command(f'{dest_filename}', expect_string=r'#')
        print(f"\n\n========Device {firewalls_strings[i]}-{each_firewall['device_type']} ========")
        i = i + 1
        print(output)
        print("++++++++ End ++++++++")
    end_time = datetime.now()
    total_time = end_time - start_time
    print(f'backup_firewalls_tftp duration : {total_time}')

def backup_network_devices_tftp(network_devices, network_devices_strings, tftp_server):
    start_time = datetime.now()
    randvalue = random.randint(1,100000)
    i = 0
    for each_device in network_devices:
        net_connect = ConnectHandler(**each_device)
        print (f"\nConnecting to {network_devices_strings[i]} and sending backup to tftp command")
        cmd = f'copy running-config tftp:'
        dest_filename = f'{network_devices_strings[i]}_{start_time.month}_{start_time.day}_{start_time.year}_{randvalue}'
        print (f'Attempting to save config as {dest_filename}')
        output = net_connect.send_command(
                cmd,
                expect_string=r'Address or name of remote host'
                )
        output += net_connect.send_command(f'{tftp_server}', expect_string=r'Destination filename')
        output += net_connect.send_command(f'{dest_filename}', expect_string=r'#')
        print(f"\n\n========Device {network_devices_strings[i]}-{each_device['device_type']} ========")
        i = i + 1
        print(output)
        print("++++++++ End ++++++++")
    end_time = datetime.now()
    total_time = end_time - start_time
    print(f'backup_network_devices_tftp duration : {total_time}')
    
def get_command():  #Gets the command to send from the user
    confirm = ''
    while "y" not in confirm:
        cmd = input("Enter command to send to device : ")
        confirm = input(f"Confirm command to send [y|n], X to cancel : {cmd} : ")
        if "y" in confirm:
            print ('Confirmed')
            return(cmd)
        elif "X" in confirm:
            print ('Cancelling')
            return (31)
            

def device_choice():    #Allows user to select from a predefined set of lists of network devices
    choice = ''
    firewall = ''
    while choice not in [1,2,3,4,5,6,7,8]:  
        choice = input(f'''
        Enter a number for which devices should receive backup/configuration
        1) All HQ Network Devices : HQ_A_SW1, HQ_A_SW2, HQ_D_SW1, HQ_D_SW2
        2) All MP Access-layer Devices : MP_A_SW1, MP_A_SW2
        3) All WH Network Devices : WH_A_SW1
        4) All Network Devices : HQ_A_SW1, HQ_A_SW2, HQ_D_SW1, HQ_D_SW2, MP_A_SW1, MP_A_SW2, MP_D_R1, MP_D_R2, WH_A_SW1
        5) All Firewalls : HQ_C_FW1, MP_C_FW1, WH_C_FW1
        6) AllSwitches : HQ_A_SW1, HQ_A_SW2, HQ_D_SW1, HQ_D_SW2, MP_A_SW1, MP_A_SW2, WH_A_SW1
        7) MP Firewalls : MP_C_FW1
        8) WH Firewalls : WH_C_FW1 
        Choice (1-8) : ''')
        choice = int(choice)
        
        #Firewalls and routers/switches should be kept in separate lists and firewalls should be a choice
              # that is >= 5 here. Connecting to asa firewalls and switches/routers requires a different
              # function so it's necessary to differentiate between the two
        if choice == 1:
            devices = HQ_network_devices
            device_string = HQ_network_devices_strings
        elif choice == 2:
            devices = MP_access_devices
            device_string = MP_access_devices_strings
        elif choice == 3:
            devices = WH_network_devices
            device_string = WH_network_devices_strings
        elif choice == 4:
            devices = all_network_devices
            device_string = all_network_devices_strings
        elif choice == 5:
            devices = all_firewalls
            device_string = all_firewalls_strings
        elif choice == 6:
            devices = AllSwitches
            device_string = AllSwitches_strings
        elif choice == 7:
            choice = MP_firewalls
            device_string = MP_firewalls_strings
        elif choice == 8:
            devices = WH_firewalls
            device_string = WH_firewalls_strings          
    if choice >= 5:
        firewall = True
    return (devices, device_string, firewall)

def backup_or_send():   #Allows user to select yes or no to if they want to perform a backup
    backup = input('Perform backup [y] or enter custom command [n] : ')
    if 'y' in backup:
        return True
    else:
        return False

def get_backup_type():  #Allows user to enter backup types from a set of options
    choice = ''
    flash = False
    tftp = False
    while choice not in [1,2,3]:
        choice = input(f'''
            What type of backup?
            1) flash
            2) tftp
            3) both
            Choice (1-3) : ''')
        choice = int(choice)

        if choice == 1:
            flash = True
        elif choice == 2:
            tftp = True
        elif choice == 3:
            flash = True
            tftp = True
    return (flash,tftp)

def main(argv):
    logfile = ''
    try:
        opts, args = getopt.getopt(argv,"hf:",["logfile="])
    except getopt.GetoptError:
        print ('bulknet.py [ -f|logfile= <logfile>]')
        sys.exit(31)
    for opt, arg in opts:
        if opt == "-h":
            print ("bulknet.py [ -o <outputfile>]")
            sys.exit(42)
        if opt in ("-f", "--logfile"):
            logfile = arg
            print (f"\t\nLogging to {logfile}\n")

    
    
    backup = backup_or_send()   #Check if user wants to back up devices or send a configuration or read command
    (devices, device_string, firewall) = device_choice()    #Allows user to select targeted devices

    if backup:
        (flash,tftp) = get_backup_type()    #get_backup_type returns booleans for flash and tftp
        if flash:
            if firewall:    #firewalls had to be separated out because they use disk0:/ instead of flash0:/ and the prompts are different
                backup_firewalls_flash(devices, device_string)
            else:
                backup_network_devices_flash(devices, device_string)
        if tftp:
            tftp_server = input("Enter IP address of tftp server : ")
            if firewall:
                backup_firewalls_tftp(devices, device_string, tftp_server)
            else:
                backup_network_devices_tftp(devices, device_string, tftp_server)
        sys.exit(42)
    
    if not backup:  #if not a backup assume the user wants to send a configuration or read command
        command = get_command() #allow user to enter command
        if isinstance(command, str):    #make sure user entered a valid string and an error wasn't returned
            if command.startswith('show'):
                if(logfile):
                    show(devices, device_string, command, logfile)
                else:
                    show(devices, device_string, command)
            else:
                configure(devices, device_string, command)
        else:
            sys.exit(31)

if __name__ == "__main__":
    main(sys.argv[1:])
    
