from flask import render_template, request, jsonify
from app import app
from app.DA_algorithm import DA_algorithm

@app.route('/', methods=['GET', 'POST'])
def index():
    matching = None

    if request.method == 'POST':
        man_number = 1 #男性を識別する数字
        man_1_list = request.get_json()  # フォームから数値を取得
        man_like_list = [man_1_list,[1,2,3,4,5],[1,2,3,4,5],[2,3,4,5,1],[5,4,3,2,1]]
        print(man_1_list)
        woman_like_list = [[1,2,3,4,5],[2,3,4,5,1],[5,4,3,2,1],[5,4,3,2,1],[5,4,3,2,1]]
        matching = DA_algorithm(man_like_list,woman_like_list,man_number)       # 素因数分解を実行
        return jsonify({"match":matching})
    return render_template('base.html')