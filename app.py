from flask import Flask
import urllib.request

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, Lacework!</p>"

@app.route("/health")
def health():
    contents = urllib.request.urlopen("https://wikipedia.com").read()
    print(contents)
    return "OK, Lacework!"

app.run(host="0.0.0.0", port=5000)