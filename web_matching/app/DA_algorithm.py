import pandas as pd
#用いた変数
# m: 男性の数
# w: 女性の数
# matchs: マッチング相手を表す辞書
# prop_list: 告白された人を表すリスト
# reject_list: 振られた人を表すリスト

#DA_algorithm
def DA_algorithm(man_like_list,woman_like_list,man_number):
#男性が告白
    m = len(man_like_list)
    w = len(woman_like_list)

    man_like_list = pd.DataFrame(man_like_list)
    man_like_list.index += 1

    woman_like_list = pd.DataFrame(woman_like_list)
    woman_like_list.index += 1

    matchs = {n : None for n in range (1,w+1)} #女性が現在保留している男性の辞書

    prop_list = [[] for _ in range(w)] #女性に告白した男性のリスト
    man_list = [_ for _ in range(1,m+1)]
    reject_list = []
    prop_count_list = [0 for _ in range(m)]

    count = 0
    while True:
        #print()
        #print(str(count+1) + "回目の告白")
        if count == 0:
            a = man_list

        for i in range(1, len(a) + 1):
            i = a[i-1]
            l = i -1
            j = prop_count_list[l]

            if man_like_list[j][i] != 0: #男性が独身を希望していない場合
                prop_list[man_like_list[j][i]-1].append(i)


                if matchs[man_like_list[j][i]] == None: #保留相手がいない場合
                    matchs[man_like_list[j][i]] = i #保留辞書に男性の番号を追加

                else: #保留相手がいる場合
                        if list(woman_like_list.loc[man_like_list[j][i]]).index(i) < list(woman_like_list.loc[man_like_list[j][i]]).index(matchs[man_like_list[j][i]]): #女性側の選好順位を比較し、新しく告白してきた男性の方が好みの場合、保留辞書を書き換える
                            reject_list.append(matchs[man_like_list[j][i]])  #振られた男性は再告白リストへ
                            matchs[man_like_list[j][i]] = i  #告白相手の順位と保留相手の順位を比較して順位が小さい方を保留相手とする

                        else:
                            reject_list.append(i) #再告白リストへ

        if reject_list == []:
            reverse_dict = {v: k for k, v in matchs.items()}
            # 検索する値
            value_to_find = man_number
            # 値からキーを検索
            key_found = reverse_dict.get(value_to_find)
            matchs = key_found
            break

        for k in range(len(reject_list)):
            prop_count_list[reject_list[k]-1] += 1

        a = reject_list
        reject_list = []

        #print("現在のマッチング相手:",matchs)
        #print("拒否された人のリスト：",a)

        count += 1

    print(matchs)

    return matchs #男性nがマッチする女性の数字を返す

