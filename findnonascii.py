#  Darren Sylvain
#  March 31, 2019
#  Search a .csv file for non-ascii characters
# This requires python3.7 because the isascii() function is new to 3.7


import sys

CRED = '\033[91m'
CEND = '\033[0m'

def usage():
    print(CRED + "Usage : python3.7 findnonascii.py <file>" + CEND)

##########################################Script start#################################################


def main():
    if len(sys.argv) < 2:
        usage()
        quit()

    FILE = sys.argv[1]
    print("File is " + FILE)

    try:
        fd = open(FILE, 'r')
    except:
        fd = None
        print("Error opening file")
    
    linenumber = 0

    for line in fd:
        linenumber = linenumber + 1
        if not line.isascii():
            print(f"Line {linenumber} : {line}")
    fd.close()



if __name__ == "__main__":
    main()
    

