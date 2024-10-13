from flask import render_template, request
from app import app
from app.utils import prime_factors  # 素因数分解関数をインポート

@app.route('/', methods=['GET', 'POST'])
def index():
    factors = None
    number = None

    if request.method == 'POST':
        number = int(request.form['number'])  # フォームから数値を取得
        factors = prime_factors(number)       # 素因数分解を実行

    return render_template('index.html', number=number, factors=factors)
