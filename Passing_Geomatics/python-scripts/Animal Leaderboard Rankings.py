import csv
with open("Animal List value.csv", newline='') as values:
    with open("survey_0.csv", newline='') as submissions:
        valuereader = csv.reader(values)
        subreader = csv.reader(submissions)
        next(valuereader)
        next(subreader)
        Animals = []
        PointValues = []
        Players = []
        Playerscore = []
        Playeranimals = []
        for i in valuereader:
            Animals.append(i[0])
            PointValues.append(i[1])
        for j in subreader:
            name = j[6]
            animal = j[9]
            if animal in Animals:
                value = int(PointValues[Animals.index(animal)])
            else:
                value = 0
                print("Invalid animal " + animal)
            if name in Players and animal in Playeranimals[Players.index(name)]:
                Playeranimals[Players.index(name)].append(animal+"(Duplicate)")
            if name in Players and animal not in Playeranimals[Players.index(name)]:
                Playeranimals[Players.index(name)].append(animal)
                Playerscore[Players.index(name)] += value
            if name not in Players:
                Players.append(name)
                Playerscore.append(value)
                Playeranimals.append([animal])
            print(Playerscore)    
                
        newps = Playerscore.copy()
        index = [0]*len(newps)

        for i in range(len(newps)):
            index[newps.index(min(newps))] = i
            newps[newps.index(min(newps))] = max(newps)+1

        #print(Players)
        print(Playerscore)
        print(newps)
        print(index)
        lengthi = len(index)
        half = lengthi/2
        print(half)
        reversed_index = []
        for i in index:
            x=abs(i-half) * 2
            if i > half:
                reversed_index.append(i-x)
            else:
                reversed_index.append(i+x)
                
        #print(Playeranimals)
     
with open("Animal Rankings.csv",'w') as rank:
    rankwriter = csv.writer(rank,lineterminator = '\n')
    rankwriter.writerow(["Player","Rank","Score","Animals"])
    for i in range(len(Players)):
        rankwriter.writerow([Players[i],reversed_index[i],Playerscore[i],Playeranimals[i]])     