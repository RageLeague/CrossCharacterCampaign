f = open("README.md", "r")
content = f.read()
string_list = content.split("\n")
outputlist = []
for i in string_list:
    outputstring = i
    hashindex = 0
    while len(i) > hashindex and i[hashindex] == "#":
        hashindex += 1
    if hashindex > 0:
        outputstring = "[h{0}]{1}[/h{0}]".format(hashindex, outputstring[hashindex + 1:])
    outputstring = outputstring.replace("`","\"")
    while "**" in outputstring:
        outputstring = outputstring.replace("**", "[b]",1)
        outputstring = outputstring.replace("**", "[/b]",1)
    outputlist.append(outputstring)
print("\n".join(outputlist))