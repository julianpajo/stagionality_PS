from flask import Flask, render_template, redirect

app = Flask(__name__)


@app.route('/oauth2/callback')
def oauth2_callback():
    return redirect("https://displacement.euler.local", code=302)


@app.route('/')
def index():
    return render_template('index.html')


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
