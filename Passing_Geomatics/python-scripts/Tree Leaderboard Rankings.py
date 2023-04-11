import csv
with open("Tree Survey Results.csv", newline='') as tree:
    treereader = csv.reader(tree)
    next(treereader)
    players = []
    playertrees = []
    for i in treereader:
        name = i[6]
        tree = i[9]
        if name in players:
            playertrees[players.index(name)].append(tree)
        else:
            players.append(name)
            playertrees.append([tree])
            
    trees = []
    tree_count = []
    for i in playertrees:
        for j in i:
            if j in trees:
                tree_count[trees.index(j)]+=1
            else:
                trees.append(j)
                tree_count.append(1)
    print(trees)
    print(tree_count)
    treesum = sum(tree_count)
    treevalue = []
    for i in tree_count:
        treevalue.append(1/(i/treesum))
    playerscore = []
    for i in playertrees:
        playerscore.append(0)
        for j in i:
            playerscore[-1] += treevalue[trees.index(j)]
    print(players)
    print(playerscore)
    newps = playerscore.copy()
    index = [0]*len(newps)

    for i in range(len(newps)):
        index[newps.index(min(newps))] = i
        newps[newps.index(min(newps))] = max(newps)+1

    #print(Players)

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
            
with open("Tree Rankings.csv",'w') as rank:
    rankwriter = csv.writer(rank,lineterminator = '\n')
    rankwriter.writerow(["Player","Rank","Score","Trees"])
    for i in range(len(players)):
        rankwriter.writerow([players[i],reversed_index[i],playerscore[i],playertrees[i]])     
        
        
        
    