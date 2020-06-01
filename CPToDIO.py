#!/usr/bin/env python3

import csv
import collections
import re
import yaml
from operator import itemgetter
import json

def sanitize(word):
    word = re.sub(r"\s+","", word)
    word = re.sub(r"-","", word)
    return word

protocols = []
source_list = []
dest_list = []
with open("ThroneCheckpoint.csv") as fp:
    reader = csv.reader(fp, delimiter=",")
    headers = next(reader)
    data_read = [row for row in reader]

#Going over data_read from the file to find all the protocols in use by rules on the firewall
for row in data_read:
    if row[3]:
        sources = row[3].split(";")
        for source in sources:
            source = sanitize(source)
            if source not in source_list: #sanitize
                source_list.append(source)
    if row[6]:
        protos = row[6].split(";")
        for proto in protos:
            proto = sanitize(proto)
            if proto not in protocols:
                protocols.append(proto)
    if row[4]:
        destinations = row[4].split(";")
        for dest in destinations:
            dest = sanitize(dest)
            if dest not in dest_list:
                dest_list.append(dest)
        

proto_csv = ",".join(protocols)
source_csv = ",".join(source_list)

all_hosts_list = list(source_list)
all_hosts_list.extend(x for x in dest_list if x not in all_hosts_list)

destDict={dest:[] for dest in dest_list}    #These are confirmed individual
dictDict = {source:{dest:[] for dest in dest_list} for source in all_hosts_list}

#iterate through rows in file again
for row in data_read:
    #Section headers start with a comma, rules start with a number
    if row[0].isdigit():                            #It's a rule!
        for source in row[3].split(";"):            #for each of the sources in the rule 
            source = sanitize(source)
            for dest in row[4].split(";"):     #For each destination in the rule
                dest = sanitize(dest)
                for proto in row[6].split(";"):         #For each protocol in the rule
                    proto = sanitize(proto)
                    if row[8] == 'Accept':
                        if not proto in dictDict.get(source).get(dest):
                            print("source = " + source + ", dest = " + dest + ", proto = " + proto)
                            for i in dictDict.get(source).get(dest):
                                print("dictDict.get(source).get(dest) : " + i)
                            try:
                                print("Appending : Source " + source + ", Destination " + dest + ", proto " + proto)
                                dictDict[source][dest].append(proto)
                            except KeyError:
                                print(f"Key error on source:{source}, destination:{dest}, proto:{proto}")

with open("output.csv","w") as output_file:
    output_file = open("output.csv","w")
    output_file.write(
'''## Habit Tracker UML use case diagram
# style: shape=%shape%;rounded=1;fillColor=%fill%;strokeColor=%stroke%;
# namespace: csvimport-
''')
    for i in protocols:
        output_file.write(r'#connect: {"from":"' + i + r'", "to":"source", "label":"' + i + r'", "style":"curved=0;endArrow=blockThin;endFill=1;dashed=1;"}' + "\n")
    output_file.write(
'''# width: auto
# height: auto
# padding: 40
# ignore: id,shape,fill,stroke,refs
# nodespacing: 40
# levelspacing: 40
# edgespacing: 40
# layout: horizontalflow
## CSV data starts below this line
''')

    output_file.write("source,shape,fill," + proto_csv + "\n")
    #output_file.write(json.dumps(dictDict))

for source in dictDict:
    outputString = ""
    outputString += source + r',ellipse,#dae8fc,'
    tempString = ""
    for proto in protocols:
        for dest in destDict:
            if proto in dictDict[source][dest]:
                tempString += dest + ","
        if tempString:
            tempString = tempString.rstrip(",")
            tempString = "\"" + tempString + "\""
            tempString += ","
            outputString += tempString
        else:
            outputString += ","
        tempString = ""
    outputString = re.sub(',$', '', outputString)
    output_file.write(outputString + "\n")




