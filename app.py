from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, Lacework!</p>"

@app.route("/health")
def health():
    return "OK, Lacework!"

app.run(host="0.0.0.0", port=5000)